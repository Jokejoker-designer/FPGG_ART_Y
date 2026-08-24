"""A7-LM-02 exact INT8 x INT16 -> INT32 reference. Must match rtl/tensor."""
from __future__ import annotations

K_TAB = (1, 7, 16, 32, 63, 64, 127, 128, 129, 192, 255, 256, 8, 24, 48, 96)
N_GEMV_TAB = (1, 15, 16, 17, 64, 100, 127, 128)
M_GEMM_TAB = (1, 3, 7, 8)
N_GEMM_TAB = (1, 8, 15, 16)
SEED0 = 0xC0FFEE00
ACT_XOR = 0xA5A55A5A
N_PAD = 128
M_PAD = 8


def xorshift32(s: int) -> int:
    s &= 0xFFFFFFFF
    s ^= (s << 13) & 0xFFFFFFFF
    s ^= (s >> 17) & 0xFFFFFFFF
    s ^= (s << 5) & 0xFFFFFFFF
    return s & 0xFFFFFFFF


def to_i8(u: int) -> int:
    u &= 0xFF
    return u - 256 if u >= 128 else u


def to_i16(u: int) -> int:
    u &= 0xFFFF
    return u - 65536 if u >= 32768 else u


def sat32(x: int) -> int:
    if x > 2147483647:
        return 2147483647
    if x < -2147483648:
        return -2147483648
    return int(x)


def sat16(x: int) -> int:
    if x > 32767:
        return 32767
    if x < -32768:
        return -32768
    return int(x)


def case_params(i: int, seed0: int = SEED0) -> dict:
    s = xorshift32((seed0 + i) & 0xFFFFFFFF)
    mode = 0 if (s & 3) != 3 else 1
    s = xorshift32(s)
    k = K_TAB[s & 15]
    s = xorshift32(s)
    if mode == 0:
        m = 1
        n = N_GEMV_TAB[s & 7]
    else:
        m = M_GEMM_TAB[s & 3]
        n = N_GEMM_TAB[(s >> 4) & 3]
    corner = (s & 31) == 0
    sat = (s & 31) == 1
    return {"i": i, "mode": mode, "M": m, "N": n, "K": k, "corner": corner, "sat": sat, "seed": seed0}


def fill_tiles(p: dict) -> tuple[list[list[int]], list[list[int]], int]:
    """W[k][n_pad], A[m_pad][k]. Returns W, A, final_ws."""
    m, n, k = p["M"], p["N"], p["K"]
    s = xorshift32((p["seed"] ^ (p["i"] * 0x9E3779B9)) & 0xFFFFFFFF)
    W = [[0] * N_PAD for _ in range(k)]
    for kk in range(k):
        for nn in range(0, N_PAD, 4):
            s = xorshift32(s)
            for t in range(4):
                col = nn + t
                val = to_i8((s >> (8 * t)) & 0xFF)
                W[kk][col] = val if col < n else 0
    s2 = xorshift32((p["seed"] ^ ACT_XOR ^ (p["i"] * 0x85EBCA6B)) & 0xFFFFFFFF)
    A = [[0] * k for _ in range(M_PAD)]
    for kk in range(k):
        for mm in range(M_PAD):
            s2 = xorshift32(s2)
            val = to_i16(s2 & 0xFFFF)
            if p["mode"] == 0:
                if mm == 0:
                    A[0][kk] = val
            else:
                A[mm][kk] = val if mm < m else 0
    if p["corner"]:
        W[0][0] = -128
        if n > 1:
            W[0][1] = 127
        A[0][0] = -32768 if (p["i"] & 1) == 0 else 32767
    if p["sat"]:
        for kk in range(k):
            for nn in range(n):
                W[kk][nn] = 127
            for mm in range(m):
                A[mm][kk] = 32767
    return W, A, s


def gemm_i32(A: list[list[int]], W: list[list[int]], m: int, n: int, k: int) -> list[list[int]]:
    out = [[0] * n for _ in range(m)]
    for mm in range(m):
        for nn in range(n):
            acc = 0
            for kk in range(k):
                acc += int(A[mm][kk]) * int(W[kk][nn])
            out[mm][nn] = sat32(acc)
    return out


def fold_psums(P: list[list[int]]) -> tuple[int, int]:
    xor32 = 0
    add32 = 0
    for row in P:
        for v in row:
            v &= 0xFFFFFFFF
            xor32 ^= v
            add32 = (add32 + v) & 0xFFFFFFFF
    return xor32, add32


def requant_row(P: list[list[int]], shift: int) -> list[list[int]]:
    return [[sat16(v >> shift) for v in row] for row in P]


def run_explicit(
    mode: int,
    m: int,
    n: int,
    k: int,
    i: int = 0,
    seed0: int = SEED0,
    corner: bool = False,
    sat: bool = False,
) -> dict:
    p = {
        "i": i,
        "mode": mode,
        "M": m,
        "N": n,
        "K": k,
        "corner": corner,
        "sat": sat,
        "seed": seed0,
    }
    W, A, _ = fill_tiles(p)
    P = gemm_i32(A, W, m, n, k)
    xor32, add32 = fold_psums(P)
    return {**p, "xor32": xor32, "add32": add32, "macs": m * n * k, "P": P}


def requant_hw_fold(P: list[list[int]], mode: int, m: int, n: int, shift: int) -> tuple[int, int]:
    """Match RTL 0x28: sat16(pmem[0:128] >>> shift), unused lanes 0."""
    xor32 = 0
    add32 = 0
    for i in range(128):
        if mode:
            mm, nn = divmod(i, 16)
            v = P[mm][nn] if mm < m and nn < n else 0
        else:
            v = P[0][i] if i < n else 0
        q = sat16(v >> shift) & 0xFFFF
        xor32 ^= q
        add32 = (add32 + q) & 0xFFFFFFFF
    return xor32, add32


def run_case(i: int, seed0: int = SEED0) -> dict:
    p = case_params(i, seed0)
    W, A, _ = fill_tiles(p)
    P = gemm_i32(A, W, p["M"], p["N"], p["K"])
    xor32, add32 = fold_psums(P)
    macs = p["M"] * p["N"] * p["K"]
    rq = requant_row(P, 0)
    rq_xor, rq_add = fold_psums([[x] for row in rq for x in row])  # unused shape
    rq_xor = 0
    rq_add = 0
    for row in rq:
        for v in row:
            v &= 0xFFFFFFFF
            rq_xor ^= v
            rq_add = (rq_add + v) & 0xFFFFFFFF
    return {
        **p,
        "xor32": xor32,
        "add32": add32,
        "macs": macs,
        "rq_xor": rq_xor,
        "P": P,
    }


def batch_fold(count: int, seed0: int = SEED0) -> dict:
    xor32 = 0
    add32 = 0
    macs = 0
    for i in range(count):
        r = run_case(i, seed0)
        xor32 ^= r["xor32"]
        add32 = (add32 + r["add32"]) & 0xFFFFFFFF
        macs += r["macs"]
    return {"count": count, "seed": seed0, "xor32": xor32, "add32": add32, "macs": macs}
