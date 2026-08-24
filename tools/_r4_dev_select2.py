"""Second DEV pass: class round-robin and 1-token mix. TRAIN/DEV already on disk."""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

from _r4_metrics import compare, evaluate  # noqa: E402
from python.ref.a7lm04_fixed_ref import LAW_ID, TinyGPT100k, recipe_sha256  # noqa: E402

OUT = ROOT / "results" / "A7-LM-04" / "candidate_r4"
DEV_INIT = (2, 3, 5, 7, 11, 13)


def load_pairs(path: Path):
    rec = json.loads(path.read_text(encoding="utf-8"))
    return [(d["p"], d["t"]) for d in rec["pairs"]], rec["sha256"]


def round_robin(pairs):
    buckets: dict[int, list] = defaultdict(list)
    for p, t in pairs:
        buckets[p[-1]].append((p, t))
    out = []
    n = max(len(v) for v in buckets.values())
    for i in range(n):
        for k in range(1, 9):
            if i < len(buckets[k]):
                out.append(buckets[k][i])
    return out


def train(model, spec, train_pairs) -> None:
    lr = spec["lr"]
    seq = round_robin(train_pairs) if spec["order"] == "rr" else list(train_pairs)
    for _ in range(spec["train_epochs"]):
        for p, t in seq:
            if spec.get("mix_one_token"):
                model.backward_full([p[-1]], t, lr=lr, apply=True)
            model.backward_full(p, t, lr=lr, apply=True)


RECIPES = [
    {"id": "lt64_e1_rr_lr3", "train_epochs": 1, "lr": 3, "order": "rr", "mix_one_token": False},
    {"id": "lt64_e2_rr_lr3", "train_epochs": 2, "lr": 3, "order": "rr", "mix_one_token": False},
    {"id": "lt64_e1_rr_mix_lr3", "train_epochs": 1, "lr": 3, "order": "rr", "mix_one_token": True},
]


def main() -> int:
    train_pairs, train_sha = load_pairs(OUT / "train.json")
    dev_pairs, dev_sha = load_pairs(OUT / "dev.json")
    need = {"median_drop": 0.15, "max_frac": 0.50, "unique_pred": 4, "entropy": 1.5}
    report = {
        "law_id": LAW_ID,
        "r3_used_for_selection": False,
        "pass": "select2_rr_mix",
        "train_sha256": train_sha,
        "dev_sha256": dev_sha,
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
        med = sorted(r["drop"] for r in rows)[len(rows) // 2]
        ok = (
            med >= need["median_drop"]
            and all(r["mean_last_loss_down"] for r in rows)
            and all(r["degrade"] <= 0.02 for r in rows)
            and all(r["max_pred_class_fraction"] <= need["max_frac"] for r in rows)
            and all(r["unique_pred_count"] >= need["unique_pred"] for r in rows)
            and all(r["pred_entropy_bits"] > need["entropy"] for r in rows)
        )
        body = {
            "law_id": LAW_ID,
            "lr": spec["lr"],
            "mix_one_token": spec["mix_one_token"],
            "order": spec["order"],
            "recipe_id": f"A7-LM-04-R4-{spec['id']}",
            "train_corpus_sha256": train_sha,
            "train_epochs": spec["train_epochs"],
        }
        rec = {
            "spec": spec,
            "recipe_sha256": recipe_sha256(body),
            "median_drop": med,
            "worst_acc": min(r["acc1"] for r in rows),
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
    }
    (OUT / "dev_select2.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report["best_seen"], indent=2), flush=True)
    print(f"can_freeze={report['can_freeze']}", flush=True)
    return 0 if report["can_freeze"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
