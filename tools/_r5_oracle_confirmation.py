"""Run the preregistered A7-LM-04 R5 confirmation oracle exactly once."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import TinyGPT100k, fold_bytes, recipe_sha256
from tools._r5_dev_target_switch import evaluate, prefix_sha256

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r5"
PREREG = OUT / "preregister.json"
DEST = OUT / "oracle_confirmation.json"
EXPECTED_PREREG_SHA = "28073459cac369e0fbc73a7b93ca1d79a983e2cdf481b57b76cbb532f0a595a2"


def main() -> int:
    if DEST.exists():
        raise RuntimeError("R5 confirmation oracle already exists; do not rerun")
    got_prereg_sha = hashlib.sha256(PREREG.read_bytes()).hexdigest()
    if got_prereg_sha != EXPECTED_PREREG_SHA:
        raise RuntimeError(f"preregister SHA changed: {got_prereg_sha}")
    prereg = json.loads(PREREG.read_text(encoding="utf-8"))
    if recipe_sha256(prereg["recipe"]) != prereg["recipe_sha256"]:
        raise RuntimeError("recipe SHA mismatch")
    if prefix_sha256(prereg["train_prefixes"]) != prereg["train_prefix_sha256"]:
        raise RuntimeError("TRAIN prefix SHA mismatch")
    if prefix_sha256(prereg["heldout_prefixes"]) != prereg["heldout_prefix_sha256"]:
        raise RuntimeError("HELDOUT prefix SHA mismatch")

    rows = []
    for seed in prereg["init_seeds"]:
        for target in prereg["targets"]:
            model = TinyGPT100k(seed)
            before = evaluate(model, prereg["heldout_prefixes"], target)
            for prefix in prereg["train_prefixes"]:
                model.backward_full(prefix, target, lr=prereg["recipe"]["lr"], apply=True)
            after = evaluate(model, prereg["heldout_prefixes"], target)
            flat = model.flat_i8()
            ce_drop = 0.0 if before["ce"] == 0 else (before["ce"] - after["ce"]) / before["ce"]
            row = {
                "seed": seed,
                "target": target,
                "before": before,
                "after": after,
                "ce_drop": ce_drop,
                "final_weight_fold": fold_bytes(flat),
                "final_weight_sha256": hashlib.sha256(bytes(v & 0xFF for v in flat)).hexdigest(),
            }
            rows.append(row)
            print(
                f"seed={seed} target={target} ce={before['ce']}->{after['ce']} "
                f"acc={after['accuracy']:.3f} lb={after['wilson_lb_95']:.3f} "
                f"dominant={after['dominant_pred']}",
                flush=True,
            )

    drops = sorted(row["ce_drop"] for row in rows)
    median_drop = (drops[len(drops) // 2 - 1] + drops[len(drops) // 2]) / 2.0
    folds_distinct = all(
        len({row["final_weight_sha256"] for row in rows if row["seed"] == seed})
        == len(prereg["targets"])
        for seed in prereg["init_seeds"]
    )
    gates = {
        "accuracy_each": all(row["after"]["accuracy"] >= prereg["gates"]["accuracy_each"] for row in rows),
        "wilson_lb_each": all(
            row["after"]["wilson_lb_95"] >= prereg["gates"]["wilson_lb_95_each"] for row in rows
        ),
        "median_ce_drop": median_drop >= prereg["gates"]["median_ce_drop"],
        "dominant_requested": all(row["after"]["dominant_pred"] == row["target"] for row in rows),
        "distinct_target_weight_sha": folds_distinct,
        "confirmation_used_for_tuning": False,
    }
    passed = all(v is False if k == "confirmation_used_for_tuning" else bool(v) for k, v in gates.items())
    report = {
        "revision": prereg["revision"],
        "preregister_sha256": got_prereg_sha,
        "recipe_sha256": prereg["recipe_sha256"],
        "train_prefix_sha256": prereg["train_prefix_sha256"],
        "heldout_prefix_sha256": prereg["heldout_prefix_sha256"],
        "rows": rows,
        "summary": {
            "median_ce_drop": median_drop,
            "worst_accuracy": min(row["after"]["accuracy"] for row in rows),
            "worst_wilson_lb_95": min(row["after"]["wilson_lb_95"] for row in rows),
        },
        "gates": gates,
        "pass": passed,
        "claim_scope": prereg["claim_scope"],
        "negative_claims": prereg["negative_claims"],
    }
    DEST.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"summary": report["summary"], "gates": gates, "pass": passed}, indent=2), flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
