"""Oracle preview: held-out vs memorization vs requant classes."""
from __future__ import annotations

import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import (
    HEAD_EPOCHS,
    HEAD_LR,
    HELDOUT,
    HELDOUT_SHA256,
    TinyGPT100k,
    board_corpus,
    heldout_ce,
    train_full_sgd,
)
from python.ref.fixed_gemm import run_case


def classify(P, mode, m, n, shift=0):
    pos = neg = none = 0
    for i in range(128):
        if mode:
            mm, nn = divmod(i, 16)
            v = P[mm][nn] if mm < m and nn < n else 0
        else:
            v = P[0][i] if i < n else 0
        s = v >> shift
        if s > 32767:
            pos += 1
        elif s < -32768:
            neg += 1
        else:
            none += 1
    return pos, neg, none


def main() -> int:
    print("HELDOUT_SHA", HELDOUT_SHA256)
    print("HELDOUT", [(p, t) for p, t in HELDOUT])
    mh = TinyGPT100k(2)
    mh.backward_head([1], 32, lr=3, apply=True)
    print("head_only_fold", mh.fold())

    print("--- train board_corpus, eval HELDOUT ---")
    for seed in (2, 3, 5):
        m1 = TinyGPT100k(seed)
        r = train_full_sgd(m1, board_corpus(8), epochs=HEAD_EPOCHS, lr=HEAD_LR)
        c0 = 256  # known
        c1 = heldout_ce(m1)
        print("seed", seed, "heldout_after", c1, "train_drop", round(r["drop"], 4))

    print("--- memorize HELDOUT (not a close path) ---")
    for seed in (2, 3, 5):
        m = TinyGPT100k(seed)
        c0 = heldout_ce(m)
        for _ in range(8):
            for pref, tgt in HELDOUT:
                m.backward_full(pref, tgt, lr=HEAD_LR, apply=True)
        c1 = heldout_ce(m)
        drop = 0.0 if c0 == 0 else (c0 - c1) / c0
        print(f"seed={seed} mem ce0={c0} ce1={c1} drop={drop:.4f}")

    print("--- requant 8/13/0 ---")
    for i in (8, 13, 0, 4):
        p = run_case(i)
        print(i, classify(p["P"], p["mode"], p["M"], p["N"], 0), "sat", p["sat"], "corner", p["corner"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
