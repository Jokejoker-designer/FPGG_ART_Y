"""Select an R4 schedule on TRAIN+DEV only. Does not create CONFIRMATION.

UART map: optional 0x3A head24+full1 on 1-token board_corpus, then
0x32+0x34 full on each TRAIN last-token pair, frozen order.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

from _r4_metrics import compare, evaluate  # noqa: E402
from python.ref.a7lm04_fixed_ref import (  # noqa: E402
    HELDOUT,
    HELDOUT_R3,
    LAW_ID,
    TinyGPT100k,
    board_corpus,
    corpus_sha256,
    last_token_corpus,
    recipe_sha256,
)

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r4"
TRAIN_N, TRAIN_SEED = 64, 71
DEV_N, DEV_SEED = 64, 73
DEV_INIT = (2, 3, 5, 7, 11, 13)
# Confirmation inits reserved: 47, 53, 61 — do not use here.


def class_order(epoch: int, mode: str) -> list[int]:
    idx = list(range(len(epoch) if False else 0))  # placeholder kept out
    return []


def ordered_pairs(pairs, epoch: int, mode: str):
    if mode == "fwd":
        return list(pairs)
    if mode == "rev":
        return list(reversed(pairs))
    if mode == "rot":
        r = (epoch * 8) % max(1, len(pairs))
        return pairs[r:] + pairs[:r]
    raise ValueError(mode)


def train(model: TinyGPT100k, spec: dict, train_pairs) -> None:
    lr = spec["lr"]
    if spec.get("use_0x3a"):
        bc = board_corpus(8)
        for _ in range(spec.get("head_epochs", 24)):
            for p, t in bc:
                model.backward_head(p, t, lr=lr, apply=True)
        model.backward_full(bc[0][0], bc[0][1], lr=lr, apply=True)
    for e in range(spec["train_epochs"]):
        for p, t in ordered_pairs(train_pairs, e, spec["order"]):
            model.backward_full(p, t, lr=lr, apply=True)


RECIPES = [
    {"id": "lt64_e2_rot_lr3", "use_0x3a": False, "train_epochs": 2, "lr": 3, "order": "rot"},
    {"id": "lt64_e4_rot_lr3", "use_0x3a": False, "train_epochs": 4, "lr": 3, "order": "rot"},
    {"id": "lt64_e2_fwd_lr3", "use_0x3a": False, "train_epochs": 2, "lr": 3, "order": "fwd"},
    {"id": "a3a_lt64_e2_rot_lr3", "use_0x3a": True, "head_epochs": 24, "train_epochs": 2, "lr": 3, "order": "rot"},
]


def recipe_body(spec: dict, train_sha: str) -> dict:
    return {
        "early_stop": False,
        "heldout_used_for_tuning": False,
        "law_id": LAW_ID,
        "lr": spec["lr"],
        "no_ce_retry": True,
        "order": spec["order"],
        "recipe_id": f"A7-LM-04-R4-{spec['id']}",
        "train_corpus": "last_token_n64_seed71",
        "train_corpus_sha256": train_sha,
        "train_epochs": spec["train_epochs"],
        "uart": "0x32+0x34 full on TRAIN; optional 0x3A warmup",
        "use_0x3a": bool(spec.get("use_0x3a")),
        "head_epochs": spec.get("head_epochs", 0),
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    block = {tuple(p) for p, _ in HELDOUT}
    block.update(tuple(p) for p, _ in HELDOUT_R3)
    train_pairs = last_token_corpus(TRAIN_N, TRAIN_SEED, block)
    block.update(tuple(p) for p, _ in train_pairs)
    dev_pairs = last_token_corpus(DEV_N, DEV_SEED, block)
    assert {tuple(p) for p, _ in train_pairs}.isdisjoint({tuple(p) for p, _ in dev_pairs})
    assert {tuple(p) for p, _ in train_pairs}.isdisjoint({tuple(p) for p, _ in HELDOUT_R3})

    train_sha = corpus_sha256(train_pairs)
    dev_sha = corpus_sha256(dev_pairs)
    (OUT / "train.json").write_text(
        json.dumps(
            {
                "role": "TRAIN",
                "n": TRAIN_N,
                "seed": TRAIN_SEED,
                "sha256": train_sha,
                "rule": "last-token k->32+(k-1)",
                "pairs": [{"p": p, "t": t} for p, t in train_pairs],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (OUT / "dev.json").write_text(
        json.dumps(
            {
                "role": "DEV",
                "n": DEV_N,
                "seed": DEV_SEED,
                "sha256": dev_sha,
                "rule": "last-token k->32+(k-1)",
                "pairs": [{"p": p, "t": t} for p, t in dev_pairs],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    # DEV freeze bar is stricter than confirmation 5% so we do not skate the gate.
    need = {
        "median_drop": 0.15,
        "mean_last_loss_down_all": True,
        "max_frac": 0.50,
        "unique_pred": 4,
        "entropy": 1.5,
        "no_degrade": True,
    }
    report = {
        "law_id": LAW_ID,
        "r3_used_for_selection": False,
        "train_sha256": train_sha,
        "dev_sha256": dev_sha,
        "dev_init_seeds": list(DEV_INIT),
        "need": need,
        "recipes": [],
        "selected": None,
        "can_freeze": False,
    }

    for spec in RECIPES:
        print(f"=== {spec['id']} ===", flush=True)
        rows = []
        for seed in DEV_INIT:
            m = TinyGPT100k(seed)
            b = evaluate(m, dev_pairs)
            train(m, spec, train_pairs)
            a = evaluate(m, dev_pairs)
            cmp = compare(b, a)
            rows.append({"seed": seed, **{k: v for k, v in cmp.items() if k not in ("after", "before")}})
            print(
                f"  seed={seed} ce {cmp['ce0']}->{cmp['ce1']} drop={cmp['drop']:.3f} "
                f"acc={cmp['acc1']:.3f} uniq={cmp['unique_pred_count']} "
                f"top={cmp['max_pred_class_fraction']:.2f} H={cmp['pred_entropy_bits']:.2f}",
                flush=True,
            )
        drops = [r["drop"] for r in rows]
        med = sorted(drops)[len(drops) // 2]
        ok = (
            med >= need["median_drop"]
            and all(r["mean_last_loss_down"] for r in rows)
            and all(r["degrade"] <= 0.02 for r in rows)
            and all(r["max_pred_class_fraction"] <= need["max_frac"] for r in rows)
            and all(r["unique_pred_count"] >= need["unique_pred"] for r in rows)
            and all(r["pred_entropy_bits"] > need["entropy"] for r in rows)
            and all(not r.get("constant_class") for r in rows)
        )
        body = recipe_body(spec, train_sha)
        rec = {
            "spec": spec,
            "recipe": body,
            "recipe_sha256": recipe_sha256(body),
            "median_drop": med,
            "worst_acc": min(r["acc1"] for r in rows),
            "worst_entropy": min(r["pred_entropy_bits"] for r in rows),
            "worst_top": max(r["max_pred_class_fraction"] for r in rows),
            "dev_ok": ok,
            "seeds": rows,
        }
        report["recipes"].append(rec)
        print(f"  median={med:.3f} dev_ok={ok}", flush=True)

    ranked = sorted(report["recipes"], key=lambda r: (r["dev_ok"], r["median_drop"], r["worst_acc"]), reverse=True)
    best = ranked[0]
    report["selected"] = best["spec"]["id"] if best["dev_ok"] else None
    report["can_freeze"] = bool(best["dev_ok"])
    report["best_seen"] = {
        "id": best["spec"]["id"],
        "dev_ok": best["dev_ok"],
        "median_drop": best["median_drop"],
        "worst_acc": best["worst_acc"],
        "recipe_sha256": best["recipe_sha256"],
    }
    (OUT / "dev_select.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report["best_seen"], indent=2), flush=True)
    print(f"can_freeze={report['can_freeze']}", flush=True)
    return 0 if report["can_freeze"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
