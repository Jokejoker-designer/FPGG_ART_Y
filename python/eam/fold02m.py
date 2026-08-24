"""eam02m-fold-v1 — not learned, not semantic. Must match a7eam02m_pkg.sv."""
from __future__ import annotations

IV = 0x0EA1020D02A70001
MASK = (1 << 64) - 1


def rotl(x: int, n: int) -> int:
    n &= 63
    x &= MASK
    return ((x << n) | (x >> (64 - n))) & MASK


def fold_step(acc: int, b: int) -> int:
    x = (acc ^ (b & 0xFF)) & MASK
    x = rotl(x, 1)
    x = (x ^ rotl(x, 8)) & MASK
    x = (x + (((b & 0xFF) << 8) | 0xA7)) & MASK
    return x


def fold_bytes(data: bytes) -> int:
    acc = IV
    for b in data:
        acc = fold_step(acc, b)
    return acc
