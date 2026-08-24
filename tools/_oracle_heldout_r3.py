"""Oracle-solvability for HELDOUT-R3 with the FROZEN recipe only.

Train: 0x3A-equivalent head24+full1 + exactly 2 full board_corpus passes.
Seeds: 17, 19, 23. Do not retune if this fails.
"""
from __future__ import annotations

import json
import math
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

from a7lm04_close_ladder_r3 import CE_DROP_MIN, collapse_guard, wilson_lb  # noqa: E402
from python.ref.a7lm04_fixed_ref import (  # noqa: E402
    HEAD_EPOCHS,
    HEAD_LR,
    HELDOUT,
    HELDOUT_R3,
    HELDOUT_R3_N,
    HELDOUT_R3_SEED,
    HELDOUT_R3_SHA256,
    INIT_SEEDS_R3,
    RECIPE_R3,
    RECIPE_R3_SHA256,
    TinyGPT100k,
    board_corpus,
    corpus_sha256,
    heldout_ce,
    recipe_sha256,
    train_full_layers,
    train_full_sgd,
)


def run_frozen_recipe(model: TinyGPT100k) -> None:
    train_full_sgd(model, board_corpus(8), epochs=HEAD_EPOCHS, lr=HEAD_LR)
    train_full_layers(model, board_corpus(8), epochs=2, lr=HEAD_LR)


def main() -> int:
    out_dir = ROOT / "results" / "A7-LM-04" / "candidate_r3"
    out_dir.mkdir(parents=True, exist_ok=True)
    assert corpus_sha256(HELDOUT_R3) == HELDOUT_R3_SHA256
    assert recipe_sha256(RECIPE_R3) == RECIPE_R3_SHA256
    assert {tuple(p) for p, _ in HELDOUT}.isdisjoint({tuple(p) for p, _ in HELDOUT_R3})

    recs = []
    for seed in INIT_SEEDS_R3:
        m = TinyGPT100k(seed)
        pairs0 = []
        for pref, tgt in HELDOUT_R3:
            pred = m.forward(pref)[1]
            pairs0.append({"p": pref, "t": tgt, "pred": pred, "loss": m.last_loss(pref, tgt)})
        c0 = sum(r["loss"] for r in pairs0)
        run_frozen_recipe(m)
        pairs1 = []
        for pref, tgt in HELDOUT_R3:
            pred = m.forward(pref)[1]
            pairs1.append({"p": pref, "t": tgt, "pred": pred, "loss": m.last_loss(pref, tgt)})
        c1 = sum(r["loss"] for r in pairs1)
        drop = 0.0 if c0 == 0 else (c0 - c1) / float(c0)
        n = len(HELDOUT_R3)
        p0 = math.exp(c0 / n)
        p1 = math.exp(c1 / n)
        col = collapse_guard(pairs1)
        rec = {
            "seed": seed,
            "ce0": c0,
            "ce1": c1,
            "drop": drop,
            "ppl0": p0,
            "ppl1": p1,
            "ppl_down": p1 < p0,
            "degrade": 0.0 if c0 == 0 else (c1 - c0) / float(c0),
            "acc0": sum(1 for r in pairs0 if r["pred"] == r["t"]) / n,
            "acc1": col["acc"],
            "collapse": col,
        }
        recs.append(rec)
        print(
            f"R3 oracle seed={seed} loss {c0}->{c1} drop={drop:.4f} "
            f"acc {rec['acc0']:.3f}->{col['acc']:.3f} classes={col['classes_hit']} "
            f"wilson_lb={col['wilson_lb_95']:.3f} collapse_ok={col['ok']}",
            flush=True,
        )

    drops = sorted(r["drop"] for r in recs)
    med = drops[1]
    ok = bool(
        med >= CE_DROP_MIN
        and all(r["ppl_down"] for r in recs)
        and all(r["degrade"] <= 0.02 for r in recs)
        and all(r["collapse"]["ok"] for r in recs)
    )
    report = {
        "revision": "A7-LM-04-HELDOUT-R3",
        "heldout_used_for_tuning": False,
        "recipe": RECIPE_R3,
        "recipe_sha256": RECIPE_R3_SHA256,
        "heldout_seed": HELDOUT_R3_SEED,
        "heldout_n": HELDOUT_R3_N,
        "heldout_sha256": HELDOUT_R3_SHA256,
        "init_seeds": list(INIT_SEEDS_R3),
        "seeds": recs,
        "median_drop": med,
        "ce_drop_min": CE_DROP_MIN,
        "ok": ok,
        "note": "Frozen recipe. If ok is false, do not retune. Report cannot close.",
    }
    (out_dir / "oracle_solvability.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"median_drop": med, "ok": ok, "recipe_sha": RECIPE_R3_SHA256}, indent=2), flush=True)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
