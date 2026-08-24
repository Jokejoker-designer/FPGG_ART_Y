"""A7-LM-06 fixed-point 4-layer 4-head GPT. law_id = lm06-signsgd-v1 (unchanged).

Same integer law as a7lm04_fixed_ref. Geometry only: V=1024 C=128 d=128 L=4 H=4 d_ff=256.
Persistent W is DDR-resident. Host oracle only.
"""
from __future__ import annotations

import hashlib
import json
import random

from python.lm.quantization import q_acc, q_act, q_grad, q_weight
from python.lm.tensor_ser import sha256_i8
from python.lm.tiny_gpt_ref import (
    ATTN_QK_SHIFT,
    BLOCK_DEADZONE,
    LIN_SHIFT,
    floor_div,
    isqrt_u32,
    step_sign,
)
from python.ref.a7lm03_fixed_ref import add, dx_from_rows, g_lin, layernorm_stats, matvec

LAW_ID = "lm06-signsgd-v1"
V = 1024
D = 128
C = 128
H = 4
L = 4
FF = 256
DH = D // H
EOS = 0
PARAM_COUNT = 2 * V * D + C * D + L * (4 * D * D + 2 * D * FF)
assert PARAM_COUNT == 802816
assert DH * H == D

OFF_TOK = 0
OFF_POS = OFF_TOK + V * D
OFF_L0 = OFF_POS + C * D
LAYER_WORDS = 4 * D * D + 2 * D * FF
OFF_HEAD = OFF_L0 + L * LAYER_WORDS
WMEM_WORDS = OFF_HEAD + V * D
assert WMEM_WORDS == 802816
assert OFF_POS == 131072
assert OFF_L0 == 147456
assert LAYER_WORDS == 131072
assert OFF_HEAD == 671744

BANK_NAMES = (
    "tok",
    "pos",
    *(n for ly in range(L) for n in (f"wq{ly}", f"wk{ly}", f"wv{ly}", f"wo{ly}", f"ff1_{ly}", f"ff2_{ly}")),
    "head",
)
BANK_SIZES = {
    "tok": V * D,
    "pos": C * D,
    **{f"wq{ly}": D * D for ly in range(L)},
    **{f"wk{ly}": D * D for ly in range(L)},
    **{f"wv{ly}": D * D for ly in range(L)},
    **{f"wo{ly}": D * D for ly in range(L)},
    **{f"ff1_{ly}": FF * D for ly in range(L)},
    **{f"ff2_{ly}": D * FF for ly in range(L)},
    "head": V * D,
}


def bank_slices() -> list[tuple[str, int, int]]:
    off = 0
    out: list[tuple[str, int, int]] = []
    for name in BANK_NAMES:
        n = BANK_SIZES[name]
        out.append((name, off, n))
        off += n
    assert off == WMEM_WORDS
    return out


def fold_bytes(blob: list[int] | bytes) -> dict[str, int]:
    xor32 = 0
    add32 = 0
    for v in blob:
        b = int(v) & 0xFF
        xor32 ^= b
        add32 = (add32 + b) & 0xFFFFFFFF
    return {"xor32": xor32, "add32": add32, "nbytes": len(blob)}


def bank_folds(blob: list[int] | bytes) -> dict[str, dict[str, int]]:
    out: dict[str, dict[str, int]] = {}
    for name, off, n in bank_slices():
        out[name] = fold_bytes(list(blob[off : off + n]))
        out[name]["off"] = off
    return out


def causal_attn_mh(q: list[list[int]], k: list[list[int]], v: list[list[int]]):
    t = len(q)
    out = [[0] * D for _ in range(t)]
    e_all: list[list[list[int]]] = []
    z_all: list[list[int]] = []
    for i in range(t):
        e_heads: list[list[int]] = []
        z_heads: list[int] = []
        for h in range(H):
            sl0 = h * DH
            scores = []
            for j in range(t):
                if j > i:
                    scores.append(-(1 << 30))
                else:
                    s = sum(int(q[i][sl0 + d]) * int(k[j][sl0 + d]) for d in range(DH))
                    scores.append(s // 4)
            mx = max(scores[: i + 1])
            exps = [max(0, sc - mx + 16) if j <= i else 0 for j, sc in enumerate(scores)]
            z = sum(exps) or 1
            for d in range(DH):
                acc = 0
                for j in range(i + 1):
                    acc += exps[j] * int(v[j][sl0 + d])
                out[i][sl0 + d] = q_act(acc // z)
            e_heads.append(exps)
            z_heads.append(z)
        e_all.append(e_heads)
        z_all.append(z_heads)
    return out, e_all, z_all


def board_corpus(n: int = 8) -> list[tuple[list[int], int]]:
    """Deterministic 1-token retrieval. FPGA emits the same pairs (no MT)."""
    pairs: list[tuple[list[int], int]] = []
    for i in range(n):
        k = 1 + (i % 8)
        tgt = 32 + (k - 1)
        pairs.append(([k], tgt))
    return pairs


def heldout_corpus_v1_invalid(n: int = 16, seed: int = 7) -> list[tuple[list[int], int]]:
    """FAIL candidate corpus: tgt independent of prefix. Do not use to close."""
    rng = random.Random(seed)
    pairs: list[tuple[list[int], int]] = []
    for _ in range(n):
        ln = 1 + rng.randint(0, 3)
        pref = [rng.randint(1, 40) for _ in range(ln)]
        tgt = 48 + rng.randint(0, 15)
        pairs.append((pref, tgt))
    return pairs


HELDOUT_V1_INVALID_SHA256 = "29d56dccf88a3e315ddfde8e65c4912041b4d5d68a99fd3dd5100ef8881873ba"
HELDOUT_SEED = 11
HELDOUT_N = 24


def heldout_corpus(n: int = HELDOUT_N, seed: int = HELDOUT_SEED) -> list[tuple[list[int], int]]:
    """Last-token retrieval with distractors. Target = 32+(k-1), k is the last token.

    Train is 1-token [k]. Held-out prefixes are length 2–4, distractors in 9..40,
    k balanced on 1..8. Same law as board_corpus; new context only.
    """
    rng = random.Random(seed)
    ks: list[int] = []
    while len(ks) < n:
        ks.extend(range(1, 9))
    ks = ks[:n]
    rng.shuffle(ks)
    pairs: list[tuple[list[int], int]] = []
    for k in ks:
        ln = rng.randint(2, 4)
        dist = [rng.randint(9, 40) for _ in range(ln - 1)]
        pref = dist + [k]
        tgt = 32 + (k - 1)
        pairs.append((pref, tgt))
    return pairs


def serialize_corpus(pairs: list[tuple[list[int], int]]) -> bytes:
    rec = [{"p": p, "t": t} for p, t in pairs]
    return json.dumps(rec, separators=(",", ":")).encode("utf-8")


def corpus_sha256(pairs: list[tuple[list[int], int]]) -> str:
    return hashlib.sha256(serialize_corpus(pairs)).hexdigest()


HELDOUT = heldout_corpus()
HELDOUT_SHA256 = corpus_sha256(HELDOUT)

# R3 confirmation set. Frozen before any board/oracle look. Do not retune.
HELDOUT_R3_SEED = 41
HELDOUT_R3_N = 128
INIT_SEEDS_R3 = (17, 19, 23)


def heldout_corpus_r3(
    n: int = HELDOUT_R3_N,
    seed: int = HELDOUT_R3_SEED,
    forbidden: set[tuple[int, ...]] | None = None,
) -> list[tuple[list[int], int]]:
    """Last-token retrieval, n=128, 8-way balanced k, prefixes disjoint from R2."""
    block = set(forbidden) if forbidden is not None else set()
    block.update(tuple(p) for p, _t in HELDOUT)
    rng = random.Random(seed)
    ks: list[int] = []
    while len(ks) < n:
        ks.extend(range(1, 9))
    ks = ks[:n]
    rng.shuffle(ks)
    pairs: list[tuple[list[int], int]] = []
    for k in ks:
        found = False
        for _ in range(10000):
            ln = rng.randint(2, 4)
            dist = [rng.randint(9, 40) for _ in range(ln - 1)]
            pref = dist + [k]
            key = tuple(pref)
            if key not in block:
                pairs.append((pref, 32 + (k - 1)))
                block.add(key)
                found = True
                break
        if not found:
            raise RuntimeError(f"unable to sample R3 prefix disjoint from R2 for k={k}")
    return pairs


HELDOUT_R3 = heldout_corpus_r3()
HELDOUT_R3_SHA256 = corpus_sha256(HELDOUT_R3)


def last_token_corpus(
    n: int,
    seed: int,
    forbidden: set[tuple[int, ...]] | None = None,
) -> list[tuple[list[int], int]]:
    """Same rule as HELDOUT-R2/R3: last token k∈1..8 → 32+(k-1); distractors 9..40.

    Used for R4 TRAIN / DEV / CONFIRMATION. Callers must keep confirmation
    unseen until the recipe is SHA-frozen.
    """
    block = set(forbidden) if forbidden is not None else set()
    rng = random.Random(seed)
    ks: list[int] = []
    while len(ks) < n:
        ks.extend(range(1, 9))
    ks = ks[:n]
    rng.shuffle(ks)
    pairs: list[tuple[list[int], int]] = []
    for k in ks:
        found = False
        for _ in range(20000):
            ln = rng.randint(2, 4)
            dist = [rng.randint(9, 40) for _ in range(ln - 1)]
            pref = dist + [k]
            key = tuple(pref)
            if key not in block:
                pairs.append((pref, 32 + (k - 1)))
                block.add(key)
                found = True
                break
        if not found:
            raise RuntimeError(f"last_token_corpus exhausted seed={seed} k={k}")
    return pairs


def recipe_r3() -> dict:
    """Frozen train recipe. Chosen from R2 validation; never adjusted after R3 look."""
    return {
        "early_stop": False,
        "extra_full_passes": 2,
        "extra_full_scope": "board_corpus_k1to8",
        "head_epochs": 24,
        "head_lr": 3,
        "head_n": 8,
        "head_opcode": "0x3A",
        "heldout_used_for_tuning": False,
        "law_id": LAW_ID,
        "no_ce_retry": True,
        "recipe_id": "A7-LM-04-R3-TRAIN-v1",
        "train_pairs": "[k]->32+(k-1) k=1..8",
    }


def recipe_sha256(rec: dict) -> str:
    return hashlib.sha256(
        json.dumps(rec, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()


RECIPE_R3 = recipe_r3()
RECIPE_R3_SHA256 = recipe_sha256(RECIPE_R3)


class TinyGPT803k:
    def __init__(self, seed: int = 2) -> None:
        rng = random.Random(seed)

        def w(r: int, c: int, mag: int = 6) -> list[list[int]]:
            return [[q_weight(rng.randint(-mag, mag)) for _ in range(c)] for _ in range(r)]

        self.tok = w(V, D)
        self.pos = w(C, D, 3)
        self.layers = []
        for _ in range(L):
            self.layers.append(
                {
                    "wq": w(D, D),
                    "wk": w(D, D),
                    "wv": w(D, D),
                    "wo": w(D, D),
                    "ff1": w(FF, D),
                    "ff2": w(D, FF),
                }
            )
        self.head = w(V, D)  # 399360-param 4-layer image

    def embed(self, tokens: list[int]) -> list[list[int]]:
        xs = []
        for i, t in enumerate(tokens[-C:]):
            xs.append([q_act(self.tok[t % V][d] + self.pos[i][d]) for d in range(D)])
        return xs

    def block(self, xs: list[list[int]], ly: dict) -> tuple[list[list[int]], dict]:
        n1 = [layernorm_stats(x)[0] for x in xs]
        q = [[q_act(v) for v in matvec(ly["wq"], x)] for x in n1]
        k = [[q_act(v) for v in matvec(ly["wk"], x)] for x in n1]
        v = [[q_act(v) for v in matvec(ly["wv"], x)] for x in n1]
        a, e, z = causal_attn_mh(q, k, v)
        wo_a = [[q_act(v) for v in matvec(ly["wo"], row)] for row in a]
        h = [[q_act(xs[i][d] + wo_a[i][d]) for d in range(D)] for i in range(len(xs))]
        n2 = [layernorm_stats(x)[0] for x in h]
        hid = []
        f_rows = []
        for x in n2:
            hh = [max(0, q_act(s)) for s in matvec(ly["ff1"], x)]
            hid.append(hh)
            f_rows.append([q_act(s) for s in matvec(ly["ff2"], hh)])
        y = [[q_act(h[i][d] + f_rows[i][d]) for d in range(D)] for i in range(len(h))]
        cache = {
            "xs": xs,
            "n1": n1,
            "q": q,
            "k": k,
            "v": v,
            "a": a,
            "e": e,
            "z": z,
            "h": h,
            "n2": n2,
            "hid": hid,
            "y": y,
        }
        return y, cache

    def hidden_states(self, tokens: list[int]) -> list[list[int]]:
        x = self.embed(tokens)
        for ly in self.layers:
            x, _ = self.block(x, ly)
        return x

    def forward(self, tokens: list[int]) -> tuple[list[int], int]:
        hs = self.hidden_states(tokens)
        if not hs:
            return [0] * V, 0
        z = matvec(self.head, hs[-1])
        pred = max(range(V), key=lambda i: (z[i], -i))
        return z, pred

    def softmax_shift(self, z: list[int]) -> tuple[list[int], int]:
        mx = max(z) if z else 0
        exps = [max(0, int(v) - mx + 16) for v in z]
        s = sum(exps) or 1
        return exps, s

    def last_loss(self, tokens: list[int], tgt: int) -> int:
        z, _ = self.forward(tokens)
        exps, s = self.softmax_shift(z)
        return int(s - exps[tgt % V])

    def last_margin(self, tokens: list[int], tgt: int) -> int:
        """Read-only: max(z) - z[tgt]. Same logits as last_loss; not used for updates."""
        z, _ = self.forward(tokens)
        return int(max(z) - z[tgt % V])

    def _bwd_layer(self, cache: dict, ly: dict, dY_last: list[int], apply: bool) -> list[int]:
        last = len(cache["xs"]) - 1
        hid = cache["hid"][last]
        n2 = cache["n2"][last]
        a_last = cache["a"][last]
        n1_last = cache["n1"][last]
        dHid = dx_from_rows(ly["ff2"], dY_last)
        dHid = [0 if hid[hh] == 0 else dHid[hh] for hh in range(FF)]
        dN2 = dx_from_rows(ly["ff1"], dHid)
        dH = [q_grad(dY_last[d] + dN2[d]) for d in range(D)]
        if apply:
            for d in range(D):
                for hh in range(FF):
                    ly["ff2"][d][hh] = q_weight(ly["ff2"][d][hh] - step_sign(g_lin(dY_last[d], hid[hh])))
            for hh in range(FF):
                for d in range(D):
                    ly["ff1"][hh][d] = q_weight(ly["ff1"][hh][d] - step_sign(g_lin(dHid[hh], n2[d])))
            for r in range(D):
                for c in range(D):
                    ly["wo"][r][c] = q_weight(ly["wo"][r][c] - step_sign(g_lin(dH[r], a_last[c])))
                    ly["wq"][r][c] = q_weight(ly["wq"][r][c] - step_sign(g_lin(dH[r], n1_last[c])))
                    ly["wk"][r][c] = q_weight(ly["wk"][r][c] - step_sign(g_lin(dH[r], n1_last[c])))
                    ly["wv"][r][c] = q_weight(ly["wv"][r][c] - step_sign(g_lin(dH[r], n1_last[c])))
        return dH

    def backward_head(
        self, tokens: list[int], tgt: int, lr: int = 3, apply: bool = True
    ) -> dict:
        rec = self.backward_full(tokens, tgt, lr=lr, apply=False, head_only=True)
        if apply:
            y = rec["y"]
            dZ = rec["dZ"]
            s = rec["s"]
            g_head = [[q_grad((dZ[v] * int(y[d])) // s) for d in range(D)] for v in range(V)]
            for v in range(V):
                for d in range(D):
                    self.head[v][d] = q_weight(self.head[v][d] - (g_head[v][d] >> lr))
        return rec

    def backward_full(
        self, tokens: list[int], tgt: int, lr: int = 8, apply: bool = True,
        head_only: bool = False,
    ) -> dict:
        if not tokens:
            return {"loss": 0}
        xs = self.embed(tokens)
        caches = []
        x = xs
        for ly in self.layers:
            x, cache = self.block(x, ly)
            caches.append(cache)
        y = x[-1]
        zlogits = matvec(self.head, y)
        exps, s = self.softmax_shift(zlogits)
        tgt = tgt % V
        dZ = [exps[v] - (s if v == tgt else 0) for v in range(V)]
        g_head = [[q_grad((dZ[v] * int(y[d])) // s) for d in range(D)] for v in range(V)]
        dY = [q_grad(sum(int(self.head[v][d]) * dZ[v] for v in range(V)) // s) for d in range(D)]
        last = tokens[-1] % V
        pos_i = len(tokens[-C:]) - 1
        if apply and not head_only:
            for v in range(V):
                for d in range(D):
                    self.head[v][d] = q_weight(self.head[v][d] - (g_head[v][d] >> lr))
            d_in = dY
            for li in range(L - 1, -1, -1):
                d_in = self._bwd_layer(caches[li], self.layers[li], d_in, True)
            for d in range(D):
                self.tok[last][d] = q_weight(self.tok[last][d] - step_sign(d_in[d]))
                self.pos[pos_i][d] = q_weight(self.pos[pos_i][d] - step_sign(d_in[d]))
        return {
            "loss": int(s - exps[tgt]),
            "s": s,
            "y": y,
            "dZ": dZ,
            "pred": max(range(V), key=lambda i: (zlogits[i], -i)),
            "dZ0": dZ[0],
            "last": last,
            "pos_i": pos_i,
            "tgt": tgt,
        }

    def named_tensors(self) -> dict[str, list[list[int]]]:
        out: dict[str, list[list[int]]] = {"tok": self.tok, "pos": self.pos}
        for li, layer in enumerate(self.layers):
            out[f"wq{li}"] = layer["wq"]
            out[f"wk{li}"] = layer["wk"]
            out[f"wv{li}"] = layer["wv"]
            out[f"wo{li}"] = layer["wo"]
            out[f"ff1_{li}"] = layer["ff1"]
            out[f"ff2_{li}"] = layer["ff2"]
        out["head"] = self.head
        return out

    def tensor_sha(self) -> dict[str, str]:
        return {k: sha256_i8(x for row in v for x in row) for k, v in self.named_tensors().items()}

    def flat_i8(self) -> list[int]:
        out: list[int] = []
        for row in self.tok:
            out.extend(int(x) for x in row)
        for row in self.pos:
            out.extend(int(x) for x in row)
        for ly in self.layers:
            for key in ("wq", "wk", "wv", "wo", "ff1", "ff2"):
                for row in ly[key]:
                    out.extend(int(x) for x in row)
        for row in self.head:
            out.extend(int(x) for x in row)
        assert len(out) == WMEM_WORDS
        return out

    def fold(self) -> dict[str, int]:
        xor32 = 0
        add32 = 0
        for v in self.flat_i8():
            b = v & 0xFF
            xor32 ^= b
            add32 = (add32 + b) & 0xFFFFFFFF
        return {"xor32": xor32, "add32": add32, "nbytes": WMEM_WORDS}

    def load_flat(self, blob: list[int]) -> None:
        assert len(blob) == WMEM_WORDS
        i = 0

        def take(r: int, c: int) -> list[list[int]]:
            nonlocal i
            rows = []
            for _ in range(r):
                rows.append([int(blob[i + k]) for k in range(c)])
                i += c
            return rows

        self.tok = take(V, D)
        self.pos = take(C, D)
        for ly in self.layers:
            ly["wq"] = take(D, D)
            ly["wk"] = take(D, D)
            ly["wv"] = take(D, D)
            ly["wo"] = take(D, D)
            ly["ff1"] = take(FF, D)
            ly["ff2"] = take(D, FF)
        self.head = take(V, D)


def corpus_loss(model: TinyGPT803k, pairs: list[tuple[list[int], int]]) -> int:
    return sum(model.last_loss(p, t) for p, t in pairs)


HEAD_EPOCHS = 24
HEAD_LR = 3


def train_full_sgd(
    model: TinyGPT803k,
    pairs: list[tuple[list[int], int]] | None = None,
    epochs: int = HEAD_EPOCHS,
    lr: int = HEAD_LR,
) -> dict:
    if pairs is None:
        pairs = board_corpus(8)
    sha0 = model.tensor_sha()
    loss0 = corpus_loss(model, pairs)
    for _ in range(epochs):
        for prefix, tgt in pairs:
            model.backward_head(prefix, tgt, lr=lr, apply=True)
    model.backward_full(pairs[0][0], pairs[0][1], lr=lr, apply=True)
    loss1 = corpus_loss(model, pairs)
    sha1 = model.tensor_sha()
    moved = {k: sha1[k] != sha0[k] for k in sha0}
    return {
        "loss0": loss0,
        "loss1": loss1,
        "drop": 0.0 if loss0 == 0 else (loss0 - loss1) / loss0,
        "moved": moved,
        "all_moved": all(moved.values()),
        "sha": sha1,
        "fold": model.fold(),
        "param_count": PARAM_COUNT,
        "law_id": LAW_ID,
        "head_epochs": epochs,
        "head_lr": lr,
    }


def heldout_ce(model: TinyGPT803k, pairs: list[tuple[list[int], int]] | None = None) -> int:
    return corpus_loss(model, HELDOUT if pairs is None else pairs)


def heldout_margin(model: TinyGPT803k, pairs: list[tuple[list[int], int]] | None = None) -> int:
    use = HELDOUT if pairs is None else pairs
    return sum(model.last_margin(p, t) for p, t in use)


def train_full_layers(
    model: TinyGPT803k,
    pairs: list[tuple[list[int], int]] | None = None,
    epochs: int = 8,
    lr: int = HEAD_LR,
) -> dict:
    """Same law_id apply path; every step is backward_full. Host/oracle only."""
    if pairs is None:
        pairs = board_corpus(8)
    sha0 = model.tensor_sha()
    loss0 = corpus_loss(model, pairs)
    for _ in range(epochs):
        for prefix, tgt in pairs:
            model.backward_full(prefix, tgt, lr=lr, apply=True)
    loss1 = corpus_loss(model, pairs)
    sha1 = model.tensor_sha()
    moved = {k: sha1[k] != sha0[k] for k in sha0}
    return {
        "loss0": loss0,
        "loss1": loss1,
        "drop": 0.0 if loss0 == 0 else (loss0 - loss1) / loss0,
        "moved": moved,
        "all_moved": all(moved.values()),
        "fold": model.fold(),
        "param_count": PARAM_COUNT,
        "law_id": LAW_ID,
        "full_epochs": epochs,
        "head_lr": lr,
    }
