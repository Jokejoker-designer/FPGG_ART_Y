"""R4 evaluation semantics. last_loss is a 0/16 integer score, not NLL.

Do not call exp(mean last_loss) perplexity.
"""
from __future__ import annotations

import math
from collections import Counter

from python.ref.a7lm04_fixed_ref import TinyGPT100k

# Frozen before confirmation eval. Relative CE uses sum(last_loss).
MIN_PRED_ENTROPY_BITS = 1.5
MAX_PRED_FRAC = 0.50
MIN_UNIQUE_PRED = 4
MAX_CE_DEGRADE = 0.02
MIN_MEDIAN_CE_DROP = 0.05
MIN_CONFIRM_N = 64


def pred_entropy_bits(preds: list[int]) -> float:
    n = len(preds)
    if n == 0:
        return 0.0
    h = 0.0
    for c in Counter(preds).values():
        p = c / n
        h -= p * math.log2(p)
    return h


def evaluate(model: TinyGPT100k, pairs: list[tuple[list[int], int]]) -> dict:
    recs = []
    for pref, tgt in pairs:
        pred = model.forward(pref)[1]
        loss = model.last_loss(pref, tgt)
        recs.append({"p": pref, "t": tgt, "pred": pred, "loss": loss, "hit": pred == tgt})
    n = len(recs)
    ce = sum(r["loss"] for r in recs)
    preds = [r["pred"] for r in recs]
    counts = Counter(preds)
    top = max(counts.values()) / n if n else 1.0
    hits = [r for r in recs if r["hit"]]
    return {
        "n": n,
        "ce_sum": ce,
        "mean_last_loss": (ce / n) if n else None,
        "exact_match_acc": (len(hits) / n) if n else 0.0,
        "correct": len(hits),
        "unique_pred_count": len(counts),
        "max_pred_class_fraction": top,
        "pred_entropy_bits": pred_entropy_bits(preds),
        "classes_hit": len({r["t"] for r in hits}),
        "pred_counts": {str(k): int(v) for k, v in sorted(counts.items())},
        "constant_class": top >= (1.0 - 1e-12),
        "pairs": recs,
    }


def compare(before: dict, after: dict) -> dict:
    c0, c1 = before["ce_sum"], after["ce_sum"]
    drop = 0.0 if not c0 else (c0 - c1) / float(c0)
    degrade = 0.0 if not c0 else (c1 - c0) / float(c0)
    mll_down = (
        before["mean_last_loss"] is not None
        and after["mean_last_loss"] is not None
        and after["mean_last_loss"] < before["mean_last_loss"]
    )
    collapse = (
        after["max_pred_class_fraction"] <= MAX_PRED_FRAC
        and after["unique_pred_count"] >= MIN_UNIQUE_PRED
        and after["pred_entropy_bits"] > MIN_PRED_ENTROPY_BITS
        and not after["constant_class"]
        and after["n"] >= MIN_CONFIRM_N
    )
    return {
        "ce0": c0,
        "ce1": c1,
        "drop": drop,
        "degrade": degrade,
        "mean_last_loss0": before["mean_last_loss"],
        "mean_last_loss1": after["mean_last_loss"],
        "mean_last_loss_down": mll_down,
        "acc0": before["exact_match_acc"],
        "acc1": after["exact_match_acc"],
        "unique_pred_count": after["unique_pred_count"],
        "max_pred_class_fraction": after["max_pred_class_fraction"],
        "pred_entropy_bits": after["pred_entropy_bits"],
        "constant_class": after["constant_class"],
        "collapse_ok": collapse,
        "after": {k: v for k, v in after.items() if k != "pairs"},
        "before": {k: v for k, v in before.items() if k != "pairs"},
    }


def gates_three_seeds(rows: list[dict]) -> dict:
    drops = [r["drop"] for r in rows]
    med = sorted(drops)[len(drops) // 2] if drops else None
    ok = bool(
        med is not None
        and med >= MIN_MEDIAN_CE_DROP
        and all(r["mean_last_loss_down"] for r in rows)
        and all(r["degrade"] <= MAX_CE_DEGRADE for r in rows)
        and all(r["collapse_ok"] for r in rows)
        and len(rows) == 3
    )
    return {
        "median_drop": med,
        "all_mean_last_loss_down": all(r["mean_last_loss_down"] for r in rows),
        "no_seed_degrade": all(r["degrade"] <= MAX_CE_DEGRADE for r in rows),
        "collapse_all": all(r["collapse_ok"] for r in rows),
        "ok": ok,
        "metric_note": "mean_last_loss is the quality proxy. It is not perplexity.",
    }
