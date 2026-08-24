"""Freeze A7-LM-04 R5 target-switch confirmation before any oracle/board look."""
from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import LAW_ID, HELDOUT, HELDOUT_R3, recipe_sha256

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r5"
DEV_REPORT = OUT / "development" / "dev_target_switch.json"
TRAIN_N = 16
HELDOUT_N = 64
TRAIN_SEED = 1101
HELDOUT_SEED = 1103
CONFIRM_INIT_SEEDS = (47, 59, 67)
CONFIRM_TARGETS = (48, 80, 112, 144)


def sha_rows(rows: list[list[int]]) -> str:
    body = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(body).hexdigest()


def sample_prefixes(n: int, seed: int, forbidden: set[tuple[int, ...]]) -> list[list[int]]:
    rng = random.Random(seed)
    rows: list[list[int]] = []
    while len(rows) < n:
        prefix = tuple(rng.randint(1, 40) for _ in range(rng.randint(2, 4)))
        if prefix not in forbidden:
            forbidden.add(prefix)
            rows.append(list(prefix))
    return rows


def main() -> int:
    if (OUT / "oracle_confirmation.json").exists():
        raise RuntimeError("R5 confirmation oracle already exists; preregistration is immutable")
    dev = json.loads(DEV_REPORT.read_text(encoding="utf-8"))
    if not dev.get("summary", {}).get("pass"):
        raise RuntimeError("R5 development did not pass")

    forbidden = {tuple(p) for p, _ in HELDOUT}
    forbidden.update(tuple(p) for p, _ in HELDOUT_R3)
    forbidden.update(tuple(p) for p in dev["train_prefixes"])
    forbidden.update(tuple(p) for p in dev["dev_prefixes"])
    train_prefixes = sample_prefixes(TRAIN_N, TRAIN_SEED, forbidden)
    heldout_prefixes = sample_prefixes(HELDOUT_N, HELDOUT_SEED, forbidden)
    assert set(map(tuple, train_prefixes)).isdisjoint(set(map(tuple, heldout_prefixes)))

    recipe = {
        "recipe_id": "A7-LM-04-R5-TARGET-SWITCH-v1",
        "law_id": LAW_ID,
        "train_prefix_count": TRAIN_N,
        "train_prefix_seed": TRAIN_SEED,
        "train_prefix_sha256": sha_rows(train_prefixes),
        "updates": "one full opcode-0x34 update per TRAIN prefix",
        "epochs": 1,
        "lr": 3,
        "early_stop": False,
        "confirmation_used_for_tuning": False,
    }
    prereg = {
        "revision": "A7-LM-04-R5-TARGET-SWITCH-CONFIRMATION",
        "frozen_before_oracle": True,
        "claim_scope": "counterfactual target-switch online adaptation; not 8-way contextual retrieval",
        "law_id": LAW_ID,
        "recipe": recipe,
        "recipe_sha256": recipe_sha256(recipe),
        "train_prefixes": train_prefixes,
        "train_prefix_sha256": sha_rows(train_prefixes),
        "heldout_prefixes": heldout_prefixes,
        "heldout_prefix_sha256": sha_rows(heldout_prefixes),
        "init_seeds": list(CONFIRM_INIT_SEEDS),
        "targets": list(CONFIRM_TARGETS),
        "gates": {
            "accuracy_each": 0.90,
            "wilson_lb_95_each": 0.80,
            "median_ce_drop": 0.90,
            "dominant_pred_equals_requested_target": True,
            "all_target_final_weight_sha_distinct_per_seed": True,
            "no_early_stop": True,
            "no_retry": True,
            "confirmation_used_for_tuning": False,
        },
        "negative_claims": [
            "not 8-way contextual retrieval",
            "not open-domain language modeling",
            "does not erase R3/R4 negative results",
        ],
    }
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "preregister.json"
    path.write_text(json.dumps(prereg, indent=2), encoding="utf-8")
    print(f"R5_PREREG={path}")
    print(f"RECIPE_SHA256={prereg['recipe_sha256']}")
    print(f"TRAIN_PREFIX_SHA256={prereg['train_prefix_sha256']}")
    print(f"HELDOUT_PREFIX_SHA256={prereg['heldout_prefix_sha256']}")
    print(f"PREREG_SHA256={hashlib.sha256(path.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
