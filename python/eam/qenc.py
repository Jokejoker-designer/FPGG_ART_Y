"""A7-EAM-02Q host encoders.

Q0 — sign of 64 selected INT16 dimensions.
Q1 — fixed ±1 hyperplanes (SimHash / random projection). Add/sub only.

Frozen law: eam02q-q1-rh-v1. Changing Q1_SEED is a new law, not a silent retune.
These maps do not prove semantic Hamming geometry. They only define a bit-exact code.
"""
from __future__ import annotations

from typing import Iterable, Sequence

D_MODEL = 128
N_BITS = 64
Q1_LAW = "eam02q-q1-rh-v1"
Q1_SEED = 0x0EA10201  # documented; do not retune on HOLD
Q0_LAW = "eam02q-q0-even-v1"

# Even indices of a 128-d last-token hidden. Frozen Q0 selection.
Q0_IDX = tuple(range(0, D_MODEL, 2))  # 64 dims
assert len(Q0_IDX) == N_BITS


def _lcg32(state: int) -> int:
    return (state * 1664525 + 1013904223) & 0xFFFFFFFF


def q1_signs(seed: int = Q1_SEED) -> tuple[tuple[int, ...], ...]:
    """64 x 128 matrix in {+1, -1}, row-major, derived from LCG32(seed)."""
    s = seed & 0xFFFFFFFF
    rows: list[tuple[int, ...]] = []
    for _i in range(N_BITS):
        row: list[int] = []
        for _j in range(D_MODEL):
            s = _lcg32(s)
            row.append(1 if (s >> 31) == 0 else -1)
        rows.append(tuple(row))
    return tuple(rows)


Q1_S = q1_signs(Q1_SEED)


def _as_h(h: Sequence[int]) -> list[int]:
    if len(h) != D_MODEL:
        raise ValueError(f"hidden must be {D_MODEL} INT16, got {len(h)}")
    out = []
    for x in h:
        v = int(x)
        if v < -32768 or v > 32767:
            raise ValueError(f"INT16 overflow {v}")
        out.append(v)
    return out


def encode_q0(h: Sequence[int]) -> int:
    h = _as_h(h)
    key = 0
    for i, j in enumerate(Q0_IDX):
        if h[j] > 0:
            key |= 1 << i
    return key


def encode_q1(h: Sequence[int], signs: Sequence[Sequence[int]] | None = None) -> int:
    h = _as_h(h)
    mat = signs if signs is not None else Q1_S
    if len(mat) != N_BITS or any(len(r) != D_MODEL for r in mat):
        raise ValueError("sign matrix must be 64 x 128")
    key = 0
    for i, row in enumerate(mat):
        acc = 0
        for s, v in zip(row, h, strict=True):
            if s not in (-1, 1):
                raise ValueError("s_ij must be ±1")
            acc += v if s == 1 else -v
        if acc > 0:
            key |= 1 << i
    return key


def hamming64(a: int, b: int) -> int:
    return (int(a) ^ int(b)).bit_count()


def encode(h: Sequence[int], rung: str = "q1") -> int:
    if rung == "q0":
        return encode_q0(h)
    if rung == "q1":
        return encode_q1(h)
    raise ValueError(f"unknown rung {rung} (q2 is not in this module)")


def twin_check(samples: Iterable[Sequence[int]] | None = None) -> dict:
    """Recompute Q1 from the seed; compare to cached Q1_S. Encode a few vectors twice."""
    rebuilt = q1_signs(Q1_SEED)
    mat_ok = rebuilt == Q1_S
    vecs = list(samples) if samples is not None else [
        [0] * D_MODEL,
        [1] * D_MODEL,
        [-3 if (i % 3) else 5 for i in range(D_MODEL)],
    ]
    mismatches = 0
    for v in vecs:
        if encode_q1(v) != encode_q1(v, rebuilt):
            mismatches += 1
        if encode_q0(v) != encode_q0(v):
            mismatches += 1
    return {
        "q0_law": Q0_LAW,
        "q1_law": Q1_LAW,
        "q1_seed": Q1_SEED,
        "matrix_frozen_ok": mat_ok,
        "encode_mismatch": mismatches,
        "pass": bool(mat_ok and mismatches == 0),
    }
