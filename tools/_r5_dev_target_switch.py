"""A7-LM-04 R5 development: counterfactual target-switch adaptation.

This is development only. It never creates or reads the R5 confirmation set.
The frozen lm05-signsgd-v1 update is used exactly as implemented by opcode 0x34.
"""
from __future__ import annotations

import hashlib
import json
import math
import random
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import LAW_ID, TinyGPT100k, fold_bytes, recipe_sha256

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r5" / "development"
TRAIN_N = 16
DEV_N = 32
TRAIN_SEED = 1001
DEV_SEED = 1003
DEV_INIT_SEEDS = (2, 3, 5)
DEV_TARGETS = (32, 33, 34, 35)


def prefix_corpus(n: int, seed: int, forbidden: set[tuple[int, ...]] | None = None):
    rng = random.Random(seed)
    used = set(forbidden or ())
    rows: list[list[int]] = []
    while len(rows) < n:
        prefix = tuple(rng.randint(1, 40) for _ in range(rng.randint(2, 4)))
        if prefix not in used:
            used.add(prefix)
            rows.append(list(prefix))
    return rows


def prefix_sha256(rows: list[list[int]]) -> str:
    body = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(body).hexdigest()


def wilson_lb(k: int, n: int, z: float = 1.959963984540054) -> float:
    if n <= 0:
        return 0.0
    p = k / float(n)
    z2 = z * z
    denom = 1.0 + z2 / n
    centre = p + z2 / (2.0 * n)
    adj = z * math.sqrt((p * (1.0 - p) + z2 / (4.0 * n)) / n)
    return (centre - adj) / denom


def evaluate(model: TinyGPT100k, prefixes: list[list[int]], target: int) -> dict:
    preds = [model.forward(prefix)[1] for prefix in prefixes]
    losses = [model.last_loss(prefix, target) for prefix in prefixes]
    counts = Counter(preds)
    correct = sum(pred == target for pred in preds)
    return {
        "n": len(prefixes),
        "ce": sum(losses),
        "mean_last_loss": sum(losses) / max(1, len(losses)),
        "correct": correct,
        "accuracy": correct / max(1, len(prefixes)),
        "wilson_lb_95": wilson_lb(correct, len(prefixes)),
        "target_share": counts.get(target, 0) / max(1, len(prefixes)),
        "dominant_pred": max(counts, key=lambda p: (counts[p], -p)) if counts else None,
        "pred_counts": {str(k): int(v) for k, v in sorted(counts.items())},
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    train_prefixes = prefix_corpus(TRAIN_N, TRAIN_SEED)
    dev_prefixes = prefix_corpus(DEV_N, DEV_SEED, {tuple(p) for p in train_prefixes})
    assert {tuple(p) for p in train_prefixes}.isdisjoint({tuple(p) for p in dev_prefixes})

    recipe = {
        "recipe_id": "A7-LM-04-R5-TARGET-SWITCH-v1",
        "law_id": LAW_ID,
        "train_prefix_count": TRAIN_N,
        "train_prefix_seed": TRAIN_SEED,
        "train_prefix_sha256": prefix_sha256(train_prefixes),
        "updates": "one full opcode-0x34 update per TRAIN prefix",
        "epochs": 1,
        "lr": 3,
        "early_stop": False,
        "confirmation_used_for_tuning": False,
    }
    report = {
        "role": "DEVELOPMENT_ONLY",
        "claim_scope": "counterfactual target-switch online adaptation; not 8-way contextual retrieval",
        "law_id": LAW_ID,
        "recipe": recipe,
        "recipe_sha256": recipe_sha256(recipe),
        "train_prefixes": train_prefixes,
        "dev_prefixes": dev_prefixes,
        "train_prefix_sha256": prefix_sha256(train_prefixes),
        "dev_prefix_sha256": prefix_sha256(dev_prefixes),
        "init_seeds": list(DEV_INIT_SEEDS),
        "targets": list(DEV_TARGETS),
        "gates": {
            "accuracy_each": 0.90,
            "wilson_lb_each": 0.75,
            "median_ce_drop": 0.90,
            "dominant_pred_equals_requested_target": True,
            "all_target_final_folds_distinct_per_seed": True,
        },
        "runs": [],
    }

    for seed in DEV_INIT_SEEDS:
        for target in DEV_TARGETS:
            model = TinyGPT100k(seed)
            before = evaluate(model, dev_prefixes, target)
            for prefix in train_prefixes:
                model.backward_full(prefix, target, lr=3, apply=True)
            after = evaluate(model, dev_prefixes, target)
            flat = model.flat_i8()
            fold = fold_bytes(flat)
            drop = 0.0 if before["ce"] == 0 else (before["ce"] - after["ce"]) / before["ce"]
            row = {
                "seed": seed,
                "target": target,
                "before": before,
                "after": after,
                "ce_drop": drop,
                "final_weight_fold": fold,
                "final_weight_sha256": hashlib.sha256(bytes(v & 0xFF for v in flat)).hexdigest(),
            }
            report["runs"].append(row)
            print(
                f"seed={seed} target={target} ce={before['ce']}->{after['ce']} "
                f"acc={after['accuracy']:.3f} lb={after['wilson_lb_95']:.3f} "
                f"dominant={after['dominant_pred']}",
                flush=True,
            )

    drops = sorted(row["ce_drop"] for row in report["runs"])
    median_drop = (drops[len(drops) // 2 - 1] + drops[len(drops) // 2]) / 2.0
    folds_distinct = all(
        len({row["final_weight_sha256"] for row in report["runs"] if row["seed"] == seed})
        == len(DEV_TARGETS)
        for seed in DEV_INIT_SEEDS
    )
    passed = bool(
        all(row["after"]["accuracy"] >= 0.90 for row in report["runs"])
        and all(row["after"]["wilson_lb_95"] >= 0.75 for row in report["runs"])
        and all(row["after"]["dominant_pred"] == row["target"] for row in report["runs"])
        and median_drop >= 0.90
        and folds_distinct
    )
    report["summary"] = {
        "median_ce_drop": median_drop,
        "worst_accuracy": min(row["after"]["accuracy"] for row in report["runs"]),
        "worst_wilson_lb_95": min(row["after"]["wilson_lb_95"] for row in report["runs"]),
        "all_target_final_folds_distinct_per_seed": folds_distinct,
        "pass": passed,
    }
    (OUT / "dev_target_switch.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report["summary"], indent=2), flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
