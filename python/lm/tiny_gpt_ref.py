"""M8-LM-03+ fixed-point 1-layer causal GPT (software golden).

V=32, d=16, C=8, heads=1, d_ff=32. INT8 weights. Softmax is integer LUT-free:
shift-max then positive ReLU-normalize (documented approximation).
"""
from __future__ import annotations

import random

from python.lm.quantization import q_acc, q_act, q_grad, q_weight
from python.lm.tensor_ser import sha256_i8

V = 32
D = 16
C = 8
FF = 32
EOS = 0

# Host/UART bank map. Integer ids only; FPGA adds the base.
BANK_TOK = 0
BANK_POS = 1
BANK_WQ = 2
BANK_WK = 3
BANK_WV = 4
BANK_WO = 5
BANK_FF1 = 6
BANK_FF2 = 7
BANK_HEAD = 8
BANK_WORDS = {
    BANK_TOK: V * D,
    BANK_POS: C * D,
    BANK_WQ: D * D,
    BANK_WK: D * D,
    BANK_WV: D * D,
    BANK_WO: D * D,
    BANK_FF1: FF * D,
    BANK_FF2: D * FF,
    BANK_HEAD: V * D,
}


def isqrt_u32(n: int) -> int:
    """Floor sqrt for LayerNorm; matches int(var**0.5) on 0..2**32-1."""
    if n <= 0:
        return 0
    lo, hi = 0, 65535
    for _ in range(16):
        mid = (lo + hi + 1) // 2
        if mid * mid <= n:
            lo = mid
        else:
            hi = mid - 1
    return lo


def floor_div(n: int, d: int) -> int:
    """Python-style floor division; d > 0."""
    return int(n) // int(d)


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


LIN_SHIFT = 4  # LM-05 linear grad: q_grad((dy * x) >> LIN_SHIFT)
ATTN_QK_SHIFT = 8  # dQ/dK: (dscore * sat16(k_or_q)) >> ATTN_QK_SHIFT
BLOCK_DEADZONE = 2  # sign-SGD on QKV/FFN/embed; head keeps g>>lr


def step_sign(g: int) -> int:
    if g > BLOCK_DEADZONE:
        return 1
    if g < -BLOCK_DEADZONE:
        return -1
    return 0


def layernorm_stats(x: list[int]) -> tuple[list[int], int, int]:
    mu = sum(x) // len(x)
    var = sum((v - mu) * (v - mu) for v in x) // len(x)
    scale = 16 if var == 0 else max(1, isqrt_u32(int(var)))
    y = [q_act((v - mu) * 16 // scale) for v in x]
    return y, int(mu), int(scale)


def layernorm_fake(x: list[int]) -> list[int]:
    return layernorm_stats(x)[0]


def g_lin(dy: int, x: int) -> int:
    return q_grad((int(dy) * int(x)) >> LIN_SHIFT)


def dx_from_rows(w_rows: list[list[int]], dy: list[int]) -> list[int]:
    """dX[i] = q_grad(sum_o W[o][i] * dy[o] >> LIN_SHIFT)."""
    if not w_rows:
        return []
    n_in = len(w_rows[0])
    out = []
    for i in range(n_in):
        s = 0
        for o, row in enumerate(w_rows):
            s += int(row[i]) * int(dy[o])
        out.append(q_grad(s >> LIN_SHIFT))
    return out


def causal_attn(
    q: list[list[int]], k: list[list[int]], v: list[list[int]], return_w: bool = False
) -> list[list[int]] | tuple[list[list[int]], list[list[int]]]:
    t = len(q)
    out = []
    weights: list[list[int]] = []
    for i in range(t):
        scores = []
        for j in range(t):
            if j > i:
                scores.append(-(1 << 30))
            else:
                s = sum(int(q[i][d]) * int(k[j][d]) for d in range(D))
                scores.append(s // 4)
        mx = max(scores[: i + 1])
        exps = [max(0, sc - mx + 16) if j <= i else 0 for j, sc in enumerate(scores)]
        z = sum(exps) or 1
        acc = [0] * D
        for j in range(i + 1):
            w = exps[j]
            for d in range(D):
                acc[d] += w * int(v[j][d])
        out.append([q_act(acc[d] // z) for d in range(D)])
        weights.append(exps)
    if return_w:
        return out, weights
    return out


class TinyGPT:
    def __init__(self, seed: int = 2) -> None:
        rng = random.Random(seed)

        def w(r: int, c: int, mag: int = 6) -> list[list[int]]:
            return [[q_weight(rng.randint(-mag, mag)) for _ in range(c)] for _ in range(r)]

        self.tok = w(V, D)
        self.pos = w(C, D, 3)
        self.wq = w(D, D)
        self.wk = w(D, D)
        self.wv = w(D, D)
        self.wo = w(D, D)
        self.ff1 = w(FF, D)
        self.ff2 = w(D, FF)
        self.head = w(V, D)

    def embed(self, tokens: list[int]) -> list[list[int]]:
        xs = []
        for i, t in enumerate(tokens[-C:]):
            xs.append([q_act(self.tok[t % V][d] + self.pos[i][d]) for d in range(D)])
        return xs

    def block(self, xs: list[list[int]]) -> list[list[int]]:
        n1 = [layernorm_fake(x) for x in xs]
        q = [matvec(self.wq, x) for x in n1]
        k = [matvec(self.wk, x) for x in n1]
        v = [matvec(self.wv, x) for x in n1]
        a = causal_attn(q, k, v)
        a = [matvec(self.wo, row) for row in a]
        h = [add(xs[i], a[i]) for i in range(len(xs))]
        n2 = [layernorm_fake(x) for x in h]
        f = []
        for x in n2:
            hid = [max(0, q_act(s)) for s in matvec(self.ff1, x)]
            f.append(matvec(self.ff2, hid))
        return [add(h[i], f[i]) for i in range(len(h))]

    def hidden_states(self, tokens: list[int]) -> list[list[int]]:
        return self.block(self.embed(tokens))

    def attn_weights(self, tokens: list[int]) -> list[list[int]]:
        xs = self.embed(tokens)
        n1 = [layernorm_fake(x) for x in xs]
        q = [matvec(self.wq, x) for x in n1]
        k = [matvec(self.wk, x) for x in n1]
        v = [matvec(self.wv, x) for x in n1]
        _out, w = causal_attn(q, k, v, return_w=True)
        return w

    def forward(self, tokens: list[int]) -> tuple[list[int], int]:
        hs = self.hidden_states(tokens)
        if not hs:
            return [0] * V, 0
        z = matvec(self.head, hs[-1])
        pred = max(range(V), key=lambda i: (z[i], -i))
        return z, pred

    def generate(self, prompt: list[int], max_new: int = 8) -> list[int]:
        seq = list(prompt)
        for _ in range(max_new):
            _, nxt = self.forward(seq)
            seq.append(nxt)
            if nxt == EOS:
                break
        return seq

    def future_mutation_prefix(self, a: list[int], b: list[int], prefix: int) -> bool:
        # Prefix hidden of the FULL sequences must match (true causal mask).
        ha = self.hidden_states(a)
        hb = self.hidden_states(b)
        return ha[:prefix] == hb[:prefix]

    def flat_bank(self, bank: int) -> list[int]:
        rows = {
            BANK_TOK: self.tok,
            BANK_POS: self.pos,
            BANK_WQ: self.wq,
            BANK_WK: self.wk,
            BANK_WV: self.wv,
            BANK_WO: self.wo,
            BANK_FF1: self.ff1,
            BANK_FF2: self.ff2,
            BANK_HEAD: self.head,
        }[bank]
        return [int(x) for row in rows for x in row]

    def tensor_sha(self) -> dict[str, str]:
        bags = {
            "tok": self.tok,
            "pos": self.pos,
            "wq": self.wq,
            "wk": self.wk,
            "wv": self.wv,
            "wo": self.wo,
            "ff1": self.ff1,
            "ff2": self.ff2,
            "head": self.head,
        }
        return {k: sha256_i8(x for row in v for x in row) for k, v in bags.items()}

    def softmax_shift(self, z: list[int]) -> tuple[list[int], int]:
        mx = max(z) if z else 0
        exps = [max(0, int(v) - mx + 16) for v in z]
        s = sum(exps) or 1
        return exps, s

    def last_loss(self, tokens: list[int], tgt: int) -> int:
        z, _ = self.forward(tokens)
        exps, s = self.softmax_shift(z)
        return int(s - exps[tgt % V])

    def backward_head_embed(
        self, tokens: list[int], tgt: int, lr: int = 8, apply: bool = True
    ) -> dict:
        """LM-04: CE via shift-max softmax. Frozen-block STE to last embed.

        Q/K/V/FFN are stop-gradient. Residuals carry dH to last tok/pos only.
        """
        if not tokens:
            return {"loss": 0, "dZ": [0] * V, "dH": [0] * D, "g_head": [], "g_tok": [0] * D, "g_pos": [0] * D}
        z, _ = self.forward(tokens)
        h = self.hidden_states(tokens)[-1]
        exps, s = self.softmax_shift(z)
        tgt = tgt % V
        dZ = [exps[v] - (s if v == tgt else 0) for v in range(V)]
        g_head = [[q_grad((dZ[v] * int(h[d])) // s) for d in range(D)] for v in range(V)]
        dH = [
            q_grad(sum(int(self.head[v][d]) * dZ[v] for v in range(V)) // s) for d in range(D)
        ]
        last = tokens[-1] % V
        pos_i = min(len(tokens), C) - 1
        if apply:
            elr = lr + 3
            for v in range(V):
                for d in range(D):
                    self.head[v][d] = q_weight(self.head[v][d] - (g_head[v][d] >> lr))
            for d in range(D):
                self.tok[last][d] = q_weight(self.tok[last][d] - (dH[d] >> elr))
                self.pos[pos_i][d] = q_weight(self.pos[pos_i][d] - (dH[d] >> elr))
        return {
            "loss": int(s - exps[tgt]),
            "s": s,
            "exps": exps,
            "dZ": dZ,
            "dH": dH,
            "g_head": g_head,
            "g_tok": list(dH),
            "g_pos": list(dH),
            "h": list(h),
            "last": last,
            "pos_i": pos_i,
            "tgt": tgt,
        }

    def sample_grads128(self, rec: dict) -> list[int]:
        """Deterministic 128-pack for board/XSim compare."""
        out: list[int] = []
        out.extend(int(x) for x in rec["dZ"])
        out.extend(int(x) for x in rec["dH"])
        out.extend(int(x) for x in rec["g_tok"])
        out.extend(int(x) for x in rec["g_pos"])
        tgt = rec["tgt"]
        for v in (0, 1, tgt):
            out.extend(int(x) for x in rec["g_head"][v])
        return out[:128]

    def sample_grads128_full(self, rec: dict) -> list[int]:
        """LM-05 pack: dZ + dY + row0 of Wq/Wk/Wv/Wo/FF2."""
        out: list[int] = []
        out.extend(int(x) for x in rec["dZ"])
        out.extend(int(x) for x in rec["dY"])
        out.extend(int(x) for x in rec["g_wq"][0])
        out.extend(int(x) for x in rec["g_wk"][0])
        out.extend(int(x) for x in rec["g_wv"][0])
        out.extend(int(x) for x in rec["g_wo"][0])
        out.extend(int(x) for x in rec["g_ff2"][0])
        return out[:128]

    def backward_full(
        self, tokens: list[int], tgt: int, lr: int = 8, apply: bool = True
    ) -> dict:
        """LM-05: CE + tiled SGD on every principal tensor.

        Integer law (matches RTL):
        - head / softmax same as LM-04 (`// s`)
        - other linear grads `q_grad((dy * x) >> LIN_SHIFT)`
        - LN backward STE (identity; LN has no trainable scale/bias)
        - attn: last query only; `dV += e*dA//z`, `dscore` STE on ReLU-exp
        """
        empty = {
            "loss": 0,
            "dZ": [0] * V,
            "dY": [0] * D,
            "dH": [0] * D,
            "g_head": [[0] * D for _ in range(V)],
            "g_wq": [[0] * D for _ in range(D)],
            "g_wk": [[0] * D for _ in range(D)],
            "g_wv": [[0] * D for _ in range(D)],
            "g_wo": [[0] * D for _ in range(D)],
            "g_ff1": [[0] * D for _ in range(FF)],
            "g_ff2": [[0] * FF for _ in range(D)],
            "g_tok": [0] * D,
            "g_pos": [0] * D,
            "tgt": tgt % V,
        }
        if not tokens:
            return empty
        xs = self.embed(tokens)
        ntok = len(xs)
        n1: list[list[int]] = []
        mu1: list[int] = []
        sc1: list[int] = []
        for x in xs:
            y, mu, sc = layernorm_stats(x)
            n1.append(y)
            mu1.append(mu)
            sc1.append(sc)
        q = [matvec(self.wq, x) for x in n1]
        k = [matvec(self.wk, x) for x in n1]
        v = [matvec(self.wv, x) for x in n1]
        a_rows, e_rows = causal_attn(q, k, v, return_w=True)
        z_attn = [sum(e_rows[i][: i + 1]) or 1 for i in range(ntok)]
        wo_a = [matvec(self.wo, row) for row in a_rows]
        h = [add(xs[i], wo_a[i]) for i in range(ntok)]
        n2: list[list[int]] = []
        sc2: list[int] = []
        for x in h:
            y, _mu, sc = layernorm_stats(x)
            n2.append(y)
            sc2.append(sc)
        hid: list[list[int]] = []
        f_rows: list[list[int]] = []
        for x in n2:
            hh = [max(0, q_act(s)) for s in matvec(self.ff1, x)]
            hid.append(hh)
            f_rows.append(matvec(self.ff2, hh))
        y = [add(h[i], f_rows[i]) for i in range(ntok)]
        zlogits = matvec(self.head, y[-1])
        exps, s = self.softmax_shift(zlogits)
        tgt = tgt % V
        dZ = [exps[v] - (s if v == tgt else 0) for v in range(V)]
        g_head = [[q_grad((dZ[v] * int(y[-1][d])) // s) for d in range(D)] for v in range(V)]
        dY = [
            q_grad(sum(int(self.head[v][d]) * dZ[v] for v in range(V)) // s) for d in range(D)
        ]
        last_h = hid[-1]
        g_ff2 = [[g_lin(dY[d], last_h[hh]) for hh in range(FF)] for d in range(D)]
        dHid = dx_from_rows(self.ff2, dY)
        dHid = [0 if last_h[hh] == 0 else dHid[hh] for hh in range(FF)]
        g_ff1 = [[g_lin(dHid[hh], n2[-1][d]) for d in range(D)] for hh in range(FF)]
        dN2 = dx_from_rows(self.ff1, dHid)
        # LN has no weights: STE (identity) keeps integer grads in range.
        dH = [q_grad(dY[d] + dN2[d]) for d in range(D)]
        g_wo = [[g_lin(dH[r], a_rows[-1][c]) for c in range(D)] for r in range(D)]
        dA = dx_from_rows(self.wo, dH)
        zlast = z_attn[-1]
        elast = e_rows[-1]
        dV = [[0] * D for _ in range(ntok)]
        dK = [[0] * D for _ in range(ntok)]
        dQ_acc = [0] * D
        q_last = [q_act(x) for x in q[-1]]
        for j in range(ntok):
            vj = [q_act(x) for x in v[j]]
            kj = [q_act(x) for x in k[j]]
            for d in range(D):
                dV[j][d] = q_grad((int(elast[j]) * int(dA[d])) // zlast)
            de = q_grad(sum(int(dA[d]) * int(vj[d]) for d in range(D)) // zlast)
            dscore = de if elast[j] > 0 else 0
            for d in range(D):
                dQ_acc[d] += (int(dscore) * int(kj[d])) >> ATTN_QK_SHIFT
                dK[j][d] = q_grad((int(dscore) * int(q_last[d])) >> ATTN_QK_SHIFT)
        dQ = [q_grad(x) for x in dQ_acc]
        g_wq = [[g_lin(dQ[r], n1[-1][c]) for c in range(D)] for r in range(D)]
        g_wk_acc = [[0] * D for _ in range(D)]
        g_wv_acc = [[0] * D for _ in range(D)]
        dN1 = [[0] * D for _ in range(ntok)]
        dN1[-1] = dx_from_rows(self.wq, dQ)
        for j in range(ntok):
            add_k = dx_from_rows(self.wk, dK[j])
            add_v = dx_from_rows(self.wv, dV[j])
            for r in range(D):
                for c in range(D):
                    g_wk_acc[r][c] += (int(dK[j][r]) * int(n1[j][c])) >> LIN_SHIFT
                    g_wv_acc[r][c] += (int(dV[j][r]) * int(n1[j][c])) >> LIN_SHIFT
                dN1[j][r] = q_grad(dN1[j][r] + add_k[r] + add_v[r])
        g_wk = [[q_grad(x) for x in row] for row in g_wk_acc]
        g_wv = [[q_grad(x) for x in row] for row in g_wv_acc]
        dXS = [list(dN1[t]) for t in range(ntok)]
        dXS[-1] = [q_grad(dXS[-1][d] + dH[d]) for d in range(D)]
        last = tokens[-1] % V
        pos_i = ntok - 1
        if apply:
            for v in range(V):
                for d in range(D):
                    self.head[v][d] = q_weight(self.head[v][d] - (g_head[v][d] >> lr))
            for d in range(D):
                for hh in range(FF):
                    self.ff2[d][hh] = q_weight(self.ff2[d][hh] - step_sign(g_ff2[d][hh]))
            for hh in range(FF):
                for d in range(D):
                    self.ff1[hh][d] = q_weight(self.ff1[hh][d] - step_sign(g_ff1[hh][d]))
            for r in range(D):
                for c in range(D):
                    self.wo[r][c] = q_weight(self.wo[r][c] - step_sign(g_wo[r][c]))
                    self.wq[r][c] = q_weight(self.wq[r][c] - step_sign(g_wq[r][c]))
                    self.wk[r][c] = q_weight(self.wk[r][c] - step_sign(g_wk[r][c]))
                    self.wv[r][c] = q_weight(self.wv[r][c] - step_sign(g_wv[r][c]))
            # Last tok/pos only (LM-04). Earlier tokens train Wk/Wv via attn.
            for d in range(D):
                self.tok[last][d] = q_weight(self.tok[last][d] - step_sign(dXS[-1][d]))
                self.pos[pos_i][d] = q_weight(self.pos[pos_i][d] - step_sign(dXS[-1][d]))
        return {
            "loss": int(s - exps[tgt]),
            "s": s,
            "exps": exps,
            "dZ": dZ,
            "dY": dY,
            "dH": dH,
            "dA": dA,
            "dQ": dQ,
            "g_head": g_head,
            "g_ff1": g_ff1,
            "g_ff2": g_ff2,
            "g_wo": g_wo,
            "g_wq": g_wq,
            "g_wk": g_wk,
            "g_wv": g_wv,
            "g_tok": list(dXS[-1]),
            "g_pos": list(dXS[-1]),
            "dXS": dXS,
            "last": last,
            "pos_i": pos_i,
            "tgt": tgt,
        }


def _sign(v: int) -> int:
    if v > 0:
        return 1
    if v < 0:
        return -1
    return 0


def synth_retrieval(n: int = 256, seed: int = 11) -> list[list[int]]:
    """Controlled key/value copy: prefix ends with k, target is paired v."""
    rng = random.Random(seed)
    rows: list[list[int]] = []
    for i in range(n):
        k = 1 + (i % 8)
        v = 16 + (k - 1)
        kind = i % 3
        if kind == 0:
            rows.append([k, v, k, v])
        elif kind == 1:
            pad = 9 + (rng.randint(0, 5))
            rows.append([k, v, pad, k, v])
        else:
            rows.append([k, v])
    return rows


def retrieval_pairs(rows: list[list[int]]) -> list[tuple[list[int], int]]:
    out: list[tuple[list[int], int]] = []
    for row in rows:
        if len(row) >= 2:
            out.append((row[:-1], row[-1]))
    return out


def retrieval_acc(model: TinyGPT, rows: list[list[int]]) -> float:
    pairs = retrieval_pairs(rows)
    if not pairs:
        return 0.0
    hit = 0
    for prefix, tgt in pairs:
        _, pred = model.forward(prefix)
        hit += int(pred == tgt)
    return hit / len(pairs)


def train_retrieval(
    model: TinyGPT,
    epochs: int = 32,
    seed: int = 11,
    train_n: int = 192,
) -> dict:
    """Host perceptron on last hidden. FPGA stays inference-only."""
    rows = synth_retrieval(256, seed)
    train_rows = rows[:train_n]
    hold_rows = rows[train_n:]
    pairs = retrieval_pairs(train_rows)
    for ep in range(epochs):
        rng = random.Random(seed + ep)
        rng.shuffle(pairs)
        for prefix, tgt in pairs:
            hs = model.hidden_states(prefix)
            if not hs:
                continue
            h = hs[-1]
            _, pred = model.forward(prefix)
            if pred == tgt:
                continue
            last = prefix[-1] % V
            pos_i = min(len(prefix), C) - 1
            for d in range(D):
                hs_s = _sign(h[d]) or 1
                model.head[tgt][d] = q_weight(model.head[tgt][d] + hs_s)
                model.head[pred][d] = q_weight(model.head[pred][d] - hs_s)
                model.tok[last][d] = q_weight(model.tok[last][d] + _sign(model.head[tgt][d]))
                model.pos[pos_i][d] = q_weight(model.pos[pos_i][d] + _sign(model.head[tgt][d]))
    return {
        "train_acc": retrieval_acc(model, train_rows),
        "hold_acc": retrieval_acc(model, hold_rows),
        "sha": model.tensor_sha(),
    }


def micro_corpus(n: int = 32, seed: int = 11) -> list[tuple[list[int], int]]:
    """Last-token only: prefix → final id. Avoids mixed intermediate pairs."""
    return [(row[:-1], row[-1]) for row in synth_retrieval(n, seed) if len(row) >= 2]


def corpus_loss(model: TinyGPT, pairs: list[tuple[list[int], int]]) -> int:
    return sum(model.last_loss(p, t) for p, t in pairs)


def train_head_embed_sgd(
    model: TinyGPT,
    pairs: list[tuple[list[int], int]],
    epochs: int = 8,
    lr: int = 8,
    seed: int = 3,
) -> dict:
    frozen_before = {k: model.tensor_sha()[k] for k in ("wq", "wk", "wv", "wo", "ff1", "ff2")}
    loss0 = corpus_loss(model, pairs)
    for ep in range(epochs):
        rng = random.Random(seed + ep)
        order = list(pairs)
        rng.shuffle(order)
        for prefix, tgt in order:
            model.backward_head_embed(prefix, tgt, lr=lr, apply=True)
    loss1 = corpus_loss(model, pairs)
    frozen_after = {k: model.tensor_sha()[k] for k in ("wq", "wk", "wv", "wo", "ff1", "ff2")}
    return {
        "loss0": loss0,
        "loss1": loss1,
        "drop": 0.0 if loss0 == 0 else (loss0 - loss1) / loss0,
        "frozen_ok": frozen_before == frozen_after,
        "sha": model.tensor_sha(),
    }


def train_full_sgd(
    model: TinyGPT,
    pairs: list[tuple[list[int], int]],
    epochs: int = 8,
    lr: int = 8,
    seed: int = 3,
    shuffle: bool = False,
) -> dict:
    sha0 = model.tensor_sha()
    loss0 = corpus_loss(model, pairs)
    for ep in range(epochs):
        order = list(pairs)
        if shuffle:
            rng = random.Random(seed + ep)
            rng.shuffle(order)
        for prefix, tgt in order:
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
        "sha": sha1,
    }
