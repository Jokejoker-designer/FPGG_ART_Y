"""A7-LM-03 fixed-point 2-layer 2-head GPT. law_id = lm05-signsgd-v1 scaled.

Same integer law as python/lm/tiny_gpt_ref.py. Only V/C/d/L/H/d_ff change.
Host is monitor/compare. Board CE / next-token / updates are FPGA-owned.
"""
from __future__ import annotations

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

LAW_ID = "lm05-signsgd-v1"
V = 128
D = 32
C = 16
H = 2
L = 2
FF = 64
DH = D // H
EOS = 0
PARAM_COUNT = 2 * V * D + C * D + L * (4 * D * D + 2 * D * FF)
assert PARAM_COUNT == 25088
assert DH * H == D

# Flat INT8 layout (must match rtl/lm/a7lm03_pkg.sv)
OFF_TOK = 0
OFF_POS = OFF_TOK + V * D
OFF_L0 = OFF_POS + C * D
LAYER_WORDS = 4 * D * D + 2 * D * FF
OFF_HEAD = OFF_L0 + L * LAYER_WORDS
WMEM_WORDS = OFF_HEAD + V * D
assert WMEM_WORDS == 25088

BANK_NAMES = (
    "tok",
    "pos",
    "wq0",
    "wk0",
    "wv0",
    "wo0",
    "ff1_0",
    "ff2_0",
    "wq1",
    "wk1",
    "wv1",
    "wo1",
    "ff1_1",
    "ff2_1",
    "head",
)
BANK_SIZES = {
    "tok": V * D,
    "pos": C * D,
    "wq0": D * D,
    "wk0": D * D,
    "wv0": D * D,
    "wo0": D * D,
    "ff1_0": FF * D,
    "ff2_0": D * FF,
    "wq1": D * D,
    "wk1": D * D,
    "wv1": D * D,
    "wo1": D * D,
    "ff1_1": FF * D,
    "ff2_1": D * FF,
    "head": V * D,
}


def bank_slices() -> list[tuple[str, int, int]]:
    """(name, offset, nbytes) in flat INT8 order. Sum is 25088."""
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


def layernorm_stats(x: list[int]) -> tuple[list[int], int, int]:
    mu = sum(x) // len(x)
    var = sum((v - mu) * (v - mu) for v in x) // len(x)
    scale = 16 if var == 0 else max(1, isqrt_u32(int(var)))
    y = [q_act((v - mu) * 16 // scale) for v in x]
    return y, int(mu), int(scale)


def matvec(w: list[list[int]], x: list[int]) -> list[int]:
    out = []
    for row in w:
        s = 0
        for a, b in zip(row, x, strict=True):
            s += int(a) * int(b)
        out.append(q_acc(s))
    return out


def add(a: list[int], b: list[int]) -> list[int]:
    return [q_act(x + y) for x, y in zip(a, b, strict=True)]


def g_lin(dy: int, x: int) -> int:
    return q_grad((int(dy) * int(x)) >> LIN_SHIFT)


def dx_from_rows(w_rows: list[list[int]], dy: list[int]) -> list[int]:
    n_in = len(w_rows[0])
    out = []
    for i in range(n_in):
        s = 0
        for o, row in enumerate(w_rows):
            s += int(row[i]) * int(dy[o])
        out.append(q_grad(s >> LIN_SHIFT))
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
        tgt = 16 + (k - 1)
        pairs.append(([k], tgt))
    return pairs


class TinyGPT25k:
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
        self.head = w(V, D)

    def embed(self, tokens: list[int]) -> list[list[int]]:
        xs = []
        for i, t in enumerate(tokens[-C:]):
            xs.append([q_act(self.tok[t % V][d] + self.pos[i][d]) for d in range(D)])
        return xs

    def block(self, xs: list[list[int]], ly: dict) -> tuple[list[list[int]], dict]:
        n1 = [layernorm_stats(x)[0] for x in xs]
        q = [matvec(ly["wq"], x) for x in n1]
        k = [matvec(ly["wk"], x) for x in n1]
        v = [matvec(ly["wv"], x) for x in n1]
        a, e, z = causal_attn_mh(q, k, v)
        wo_a = [matvec(ly["wo"], row) for row in a]
        h = [add(xs[i], wo_a[i]) for i in range(len(xs))]
        n2 = [layernorm_stats(x)[0] for x in h]
        hid = []
        f_rows = []
        for x in n2:
            hh = [max(0, q_act(s)) for s in matvec(ly["ff1"], x)]
            hid.append(hh)
            f_rows.append(matvec(ly["ff2"], hh))
        y = [add(h[i], f_rows[i]) for i in range(len(h))]
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

    def _bwd_layer(self, cache: dict, ly: dict, dY_last: list[int], apply: bool) -> list[int]:
        """Last-token outer-product sign-SGD on every linear bank. Returns dH."""
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
        """Primary learner: language-head CE only (lm05 head law)."""
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
        return {
            "tok": self.tok,
            "pos": self.pos,
            "wq0": self.layers[0]["wq"],
            "wk0": self.layers[0]["wk"],
            "wv0": self.layers[0]["wv"],
            "wo0": self.layers[0]["wo"],
            "ff1_0": self.layers[0]["ff1"],
            "ff2_0": self.layers[0]["ff2"],
            "wq1": self.layers[1]["wq"],
            "wk1": self.layers[1]["wk"],
            "wv1": self.layers[1]["wv"],
            "wo1": self.layers[1]["wo"],
            "ff1_1": self.layers[1]["ff1"],
            "ff2_1": self.layers[1]["ff2"],
            "head": self.head,
        }

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


def corpus_loss(model: TinyGPT25k, pairs: list[tuple[list[int], int]]) -> int:
    return sum(model.last_loss(p, t) for p, t in pairs)


HEAD_EPOCHS = 24
HEAD_LR = 3


def train_full_sgd(
    model: TinyGPT25k,
    pairs: list[tuple[list[int], int]] | None = None,
    epochs: int = HEAD_EPOCHS,
    lr: int = HEAD_LR,
) -> dict:
    """24 head-only epochs, then one full last-query sign-SGD step (all banks)."""
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
