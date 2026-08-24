"""R4 recipe development. Tune only on R2 + new DEV corpora.

Never reads HELDOUT-R3 for selection. Does not create HELDOUT-R4.
law_id stays lm05-signsgd-v1. UART-mappable: 0x3A then host 0x34 order.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import (
    HELDOUT,
    HELDOUT_R3,
    LAW_ID,
    TinyGPT100k,
    board_corpus,
    corpus_sha256,
    heldout_corpus,
)

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r4"
DEV_SEEDS = (2, 3, 5, 7, 11, 13, 29, 31, 37, 43)
# Confirmation seeds reserved: 17,19,23 (R3) and later R4 inits. Do not use here.


def class_order(epoch: int, mode: str) -> list[int]:
    ks = list(range(1, 9))
    if mode == "fwd":
        return ks
    if mode == "rev":
        return list(reversed(ks))
    if mode == "rot":
        r = epoch % 8
        return ks[r:] + ks[:r]
    if mode == "rot_rev":
        r = epoch % 8
        xs = ks[r:] + ks[:r]
        return list(reversed(xs)) if epoch % 2 else xs
    raise ValueError(mode)


def train_schedule(model: TinyGPT100k, spec: dict) -> None:
    lr = spec["lr"]
    train = board_corpus(8)
    if spec.get("use_0x3a", True):
        for _ in range(spec["head_epochs"]):
            for prefix, tgt in train:
                model.backward_head(prefix, tgt, lr=lr, apply=True)
        if spec.get("head_full1", True):
            model.backward_full(train[0][0], train[0][1], lr=lr, apply=True)
    for e in range(spec["full_passes"]):
        for k in class_order(e, spec["order"]):
            model.backward_full([k], 32 + (k - 1), lr=lr, apply=True)


def eval_pairs(model: TinyGPT100k, pairs: list[tuple[list[int], int]]) -> dict:
    recs = []
    for pref, tgt in pairs:
        pred = model.forward(pref)[1]
        recs.append({"t": tgt, "pred": pred, "loss": model.last_loss(pref, tgt), "hit": pred == tgt})
    n = len(recs)
    ce = sum(r["loss"] for r in recs)
    hits = [r for r in recs if r["hit"]]
    acc = len(hits) / n if n else 0.0
    preds = [r["pred"] for r in recs]
    counts = Counter(preds)
    top_share = (max(counts.values()) / n) if n else 1.0
    classes_hit = len({r["t"] for r in hits} & {32 + k - 1 for k in range(1, 9)})
    return {
        "n": n,
        "ce": ce,
        "acc": acc,
        "correct": len(hits),
        "classes_hit": classes_hit,
        "top_pred_share": top_share,
        "pred_counts": {str(k): int(v) for k, v in sorted(counts.items())},
    }


def collapse_ok(ev: dict) -> bool:
    return ev["acc"] >= 0.25 and ev["classes_hit"] >= 7 and ev["top_pred_share"] <= 0.40


def make_dev_corpus(n: int, seed: int, forbidden: set[tuple[int, ...]]):
    return heldout_corpus.__wrapped__(n, seed) if hasattr(heldout_corpus, "__wrapped__") else _sample(n, seed, forbidden)


def _sample(n: int, seed: int, forbidden: set[tuple[int, ...]]):
    import random

    rng = random.Random(seed)
    ks: list[int] = []
    while len(ks) < n:
        ks.extend(range(1, 9))
    ks = ks[:n]
    rng.shuffle(ks)
    block = set(forbidden)
    pairs: list[tuple[list[int], int]] = []
    for k in ks:
        for _ in range(20000):
            ln = rng.randint(2, 4)
            dist = [rng.randint(9, 40) for _ in range(ln - 1)]
            pref = dist + [k]
            key = tuple(pref)
            if key not in block:
                pairs.append((pref, 32 + (k - 1)))
                block.add(key)
                break
        else:
            raise RuntimeError(f"dev sample failed seed={seed} k={k}")
    return pairs


RECIPES = [
    {"id": "r3_control", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 2, "lr": 3, "order": "fwd"},
    {"id": "h24_f8_rot", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 3, "order": "rot"},
    {"id": "h24_f8_rotrev", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 3, "order": "rot_rev"},
    {"id": "h24_f8_rev", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 3, "order": "rev"},
    {"id": "h24_f8_fwd", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 3, "order": "fwd"},
    {"id": "h48_f4_rot", "use_0x3a": True, "head_epochs": 48, "head_full1": True, "full_passes": 4, "lr": 3, "order": "rot"},
    {"id": "h24_f8_rot_lr2", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 2, "order": "rot"},
    {"id": "h24_f8_rot_lr4", "use_0x3a": True, "head_epochs": 24, "head_full1": True, "full_passes": 8, "lr": 4, "order": "rot"},
]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    forbidden = {tuple(p) for p, _ in HELDOUT}
    forbidden.update(tuple(p) for p, _ in HELDOUT_R3)
    dev_a = _sample(64, 53, forbidden)
    forbidden.update(tuple(p) for p, _ in dev_a)
    dev_b = _sample(64, 59, forbidden)
    sets = {
        "R2": HELDOUT,
        "DEV_A_s53_n64": dev_a,
        "DEV_B_s59_n64": dev_b,
    }
    set_meta = {
        name: {
            "n": len(pairs),
            "sha256": corpus_sha256(pairs),
            "role": "development",
            "disjoint_r3": {tuple(p) for p, _ in pairs}.isdisjoint({tuple(q) for q, _ in HELDOUT_R3}),
        }
        for name, pairs in sets.items()
    }
    (OUT / "dev_corpora.json").write_text(
        json.dumps(
            {
                "law_id": LAW_ID,
                "note": "Development only. Not confirmation. R3 prefixes blocked.",
                "sets": set_meta,
                "DEV_A": [{"p": p, "t": t} for p, t in dev_a],
                "DEV_B": [{"p": p, "t": t} for p, t in dev_b],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    freeze_need = {
        "n_seeds": 10,
        "median_ce_drop": 0.30,
        "acc_each": 0.25,
        "classes_hit": 7,
        "top_share": 0.40,
        "no_degrade": True,
    }
    report = {
        "law_id": LAW_ID,
        "heldout_r3_used_for_selection": False,
        "dev_seeds": list(DEV_SEEDS),
        "sets": set_meta,
        "freeze_requirement": freeze_need,
        "recipes": [],
        "selected": None,
        "can_freeze": False,
    }

    for spec in RECIPES:
        rec = {"spec": spec, "by_set": {}, "uart": "0x3A(n=8,ep,lr) then 0x34 full in order"}
        print(f"=== {spec['id']} ===", flush=True)
        per_set: dict[str, list] = {name: [] for name in sets}
        for seed in DEV_SEEDS:
            m = TinyGPT100k(seed)
            before = {name: eval_pairs(m, pairs) for name, pairs in sets.items()}
            train_schedule(m, spec)
            after = {name: eval_pairs(m, pairs) for name, pairs in sets.items()}
            for set_name in sets:
                b, a = before[set_name], after[set_name]
                drop = 0.0 if b["ce"] == 0 else (b["ce"] - a["ce"]) / float(b["ce"])
                degrade = a["ce"] > b["ce"]
                row = {
                    "seed": seed,
                    "ce0": b["ce"],
                    "ce1": a["ce"],
                    "drop": drop,
                    "acc0": b["acc"],
                    "acc1": a["acc"],
                    "classes_hit": a["classes_hit"],
                    "top_pred_share": a["top_pred_share"],
                    "degrade": degrade,
                    "collapse_ok": collapse_ok(a) and not degrade,
                }
                per_set[set_name].append(row)
            a_r2 = after["R2"]
            print(
                f"  seed={seed} R2 ce {before['R2']['ce']}->{a_r2['ce']} "
                f"drop={(0 if before['R2']['ce']==0 else (before['R2']['ce']-a_r2['ce'])/before['R2']['ce']):.3f} "
                f"acc={a_r2['acc']:.3f} cls={a_r2['classes_hit']} top={a_r2['top_pred_share']:.2f}",
                flush=True,
            )
        freeze_ok = True
        for set_name, seed_rows in per_set.items():
            drops = [r["drop"] for r in seed_rows]
            med = sorted(drops)[len(drops) // 2]
            worst_acc = min(r["acc1"] for r in seed_rows)
            worst_cls = min(r["classes_hit"] for r in seed_rows)
            worst_top = max(r["top_pred_share"] for r in seed_rows)
            any_deg = any(r["degrade"] for r in seed_rows)
            set_ok = (
                med >= freeze_need["median_ce_drop"]
                and all(r["acc1"] >= freeze_need["acc_each"] for r in seed_rows)
                and worst_cls >= freeze_need["classes_hit"]
                and worst_top <= freeze_need["top_share"]
                and not any_deg
            )
            freeze_ok = freeze_ok and set_ok
            rec["by_set"][set_name] = {
                "median_drop": med,
                "worst_acc": worst_acc,
                "worst_classes_hit": worst_cls,
                "worst_top_share": worst_top,
                "any_degrade": any_deg,
                "set_ok": set_ok,
                "seeds": seed_rows,
            }
        rec["freeze_ok"] = freeze_ok
        rec["score"] = min(rec["by_set"][s]["worst_acc"] for s in sets)
        report["recipes"].append(rec)
        print(f"  freeze_ok={freeze_ok} worst_acc={rec['score']:.3f}", flush=True)

    ranked = sorted(report["recipes"], key=lambda r: (r["freeze_ok"], r["score"]), reverse=True)
    best = ranked[0]
    report["selected"] = best["spec"]["id"] if best["freeze_ok"] else None
    report["can_freeze"] = bool(best["freeze_ok"])
    report["best_seen"] = {
        "id": best["spec"]["id"],
        "freeze_ok": best["freeze_ok"],
        "worst_acc": best["score"],
        "by_set": {k: {kk: vv for kk, vv in v.items() if kk != "seeds"} for k, v in best["by_set"].items()},
    }
    (OUT / "dev_sweep.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report["best_seen"], indent=2), flush=True)
    print(f"can_freeze={report['can_freeze']}", flush=True)
    return 0 if report["can_freeze"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
