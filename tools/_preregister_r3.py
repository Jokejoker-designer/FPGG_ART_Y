"""Write frozen R3 recipe + HELDOUT preregister. No board. No look-then-edit."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import (
    HELDOUT,
    HELDOUT_R3,
    HELDOUT_R3_N,
    HELDOUT_R3_SEED,
    HELDOUT_R3_SHA256,
    HELDOUT_SHA256,
    HELDOUT_V1_INVALID_SHA256,
    INIT_SEEDS_R3,
    RECIPE_R3,
    RECIPE_R3_SHA256,
    corpus_sha256,
    recipe_sha256,
)


def main() -> int:
    out = ROOT / "results" / "A7-LM-04" / "candidate_r3"
    out.mkdir(parents=True, exist_ok=True)
    assert corpus_sha256(HELDOUT_R3) == HELDOUT_R3_SHA256
    assert recipe_sha256(RECIPE_R3) == RECIPE_R3_SHA256
    assert {tuple(p) for p, _ in HELDOUT}.isdisjoint({tuple(p) for p, _ in HELDOUT_R3})
    recipe = {
        **RECIPE_R3,
        "sha256": RECIPE_R3_SHA256,
        "frozen_before_r3_eval": True,
        "validation_set": "HELDOUT-R2",
        "confirmation_set": "HELDOUT-R3",
    }
    (out / "recipe.json").write_text(json.dumps(recipe, indent=2, sort_keys=True), encoding="utf-8")
    pre = {
        "revision": "A7-LM-04-HELDOUT-R3",
        "frozen_before_board": True,
        "heldout_used_for_tuning": False,
        "seed": HELDOUT_R3_SEED,
        "n": HELDOUT_R3_N,
        "sha256": HELDOUT_R3_SHA256,
        "r2_sha256": HELDOUT_SHA256,
        "v1_invalid_sha256": HELDOUT_V1_INVALID_SHA256,
        "init_seeds": list(INIT_SEEDS_R3),
        "recipe_sha256": RECIPE_R3_SHA256,
        "law_id": "lm05-signsgd-v1",
        "task": "last-token retrieval with distractors; tgt=32+(k-1); k=last token in 1..8; distractors 9..40; prefix length 2..4; prefixes disjoint from R2",
        "train": "[k] -> 32+(k-1), k in 1..8",
        "oracle_recipe": "frozen A7-LM-04-R3-TRAIN-v1: head24+full1 + exactly 2 full board_corpus passes, lr=3",
        "pairs": [{"p": p, "t": t} for p, t in HELDOUT_R3],
    }
    (out / "heldout_preregister.json").write_text(json.dumps(pre, indent=2), encoding="utf-8")
    print(f"R3_HELDOUT_SHA={HELDOUT_R3_SHA256}")
    print(f"R3_RECIPE_SHA={RECIPE_R3_SHA256}")
    print(f"wrote {out / 'recipe.json'}")
    print(f"wrote {out / 'heldout_preregister.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
