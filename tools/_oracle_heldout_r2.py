"""Oracle-solvability for HELDOUT r2. Train on board_corpus only. No board."""
from __future__ import annotations

import json
import math
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import (
    HEAD_EPOCHS,
    HEAD_LR,
    HELDOUT,
    HELDOUT_N,
    HELDOUT_SEED,
    HELDOUT_SHA256,
    HELDOUT_V1_INVALID_SHA256,
    TinyGPT100k,
    board_corpus,
    corpus_sha256,
    heldout_ce,
    heldout_corpus_v1_invalid,
    heldout_margin,
    train_full_layers,
    train_full_sgd,
)


def gates(c0: int, c1: int, n: int) -> dict:
    drop = 0.0 if c0 == 0 else (c0 - c1) / float(c0)
    # Stable monotonic PPL proxy. last_loss means are O(16); margins can be huge.
    scale = 64.0 if abs(c0) + abs(c1) > 4096 else 1.0
    p0 = math.exp(max(-20.0, min(20.0, (c0 / max(1, n)) / scale)))
    p1 = math.exp(max(-20.0, min(20.0, (c1 / max(1, n)) / scale)))
    deg = 0.0 if c0 == 0 else (c1 - c0) / float(c0)
    return {
        "ce0": c0,
        "ce1": c1,
        "drop": drop,
        "ppl0": p0,
        "ppl1": p1,
        "ppl_down": p1 < p0,
        "degrade": deg,
        "degrade_ok": deg <= 0.02,
    }


def run_recipe(name: str, train_fn) -> dict:
    recs = []
    for seed in (2, 3, 5):
        m = TinyGPT100k(seed)
        c0 = heldout_ce(m)
        m0 = heldout_margin(m)
        a0 = sum(1 for p, t in HELDOUT if m.forward(p)[1] == t)
        train_fn(m)
        c1 = heldout_ce(m)
        m1 = heldout_margin(m)
        a1 = sum(1 for p, t in HELDOUT if m.forward(p)[1] == t)
        g_ce = gates(c0, c1, len(HELDOUT))
        g_mg = gates(m0, m1, len(HELDOUT))
        recs.append(
            {
                "seed": seed,
                "loss": g_ce,
                "margin": g_mg,
                "acc0": a0,
                "acc1": a1,
                "train_ce_board": None,
            }
        )
        print(
            f"{name} seed={seed} loss {c0}->{c1} drop={g_ce['drop']:.4f} "
            f"margin {m0}->{m1} drop={g_mg['drop']:.4f} acc {a0}->{a1}",
            flush=True,
        )
    def pack(key: str) -> dict:
        xs = [r[key] for r in recs]
        drops = [x["drop"] for x in xs]
        med = sorted(drops)[1]
        return {
            "median_drop": med,
            "all_ppl_down": all(x["ppl_down"] for x in xs),
            "no_degrade": all(x["degrade_ok"] for x in xs),
            "ok": med >= 0.05 and all(x["ppl_down"] for x in xs) and all(x["degrade_ok"] for x in xs),
        }
    return {"recipe": name, "seeds": recs, "loss_gate": pack("loss"), "margin_gate": pack("margin")}


def main() -> int:
    assert corpus_sha256(heldout_corpus_v1_invalid()) == HELDOUT_V1_INVALID_SHA256
    lasts = [p[-1] for p, _t in HELDOUT]
    counts = Counter(lasts)
    print("HELDOUT_N", len(HELDOUT), "SEED", HELDOUT_SEED, "SHA", HELDOUT_SHA256)
    print("k_counts", dict(sorted(counts.items())))
    print("lens", Counter(len(p) for p, _ in HELDOUT))
    print("sample", HELDOUT[:4])
    assert len(HELDOUT) == HELDOUT_N
    assert all(2 <= len(p) <= 4 for p, _ in HELDOUT)
    assert all(p[-1] in range(1, 9) for p, _ in HELDOUT)
    assert all(all(x >= 9 for x in pref[:-1]) for pref, _ in HELDOUT)
    assert all(t == 32 + (pref[-1] - 1) for pref, t in HELDOUT)
    assert set(lasts) == set(range(1, 9))

    recipes = [
        (
            "head24_full1",
            lambda m: train_full_sgd(m, board_corpus(8), epochs=HEAD_EPOCHS, lr=HEAD_LR),
        ),
        (
            "full8",
            lambda m: train_full_layers(m, board_corpus(8), epochs=8, lr=HEAD_LR),
        ),
        (
            "full16",
            lambda m: train_full_layers(m, board_corpus(8), epochs=16, lr=HEAD_LR),
        ),
    ]
    out = {
        "heldout_sha": HELDOUT_SHA256,
        "heldout_n": len(HELDOUT),
        "heldout_seed": HELDOUT_SEED,
        "heldout": [{"p": p, "t": t} for p, t in HELDOUT],
        "recipes": [],
    }
    for name, fn in recipes:
        print("===", name, "===", flush=True)
        out["recipes"].append(run_recipe(name, fn))
    dest = ROOT / "results" / "A7-LM-04" / "candidate_r2"
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "oracle_solvability.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(json.dumps({r["recipe"]: {"loss": r["loss_gate"], "margin": r["margin_gate"]} for r in out["recipes"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
