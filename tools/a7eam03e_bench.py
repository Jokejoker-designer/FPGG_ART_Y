"""A7-SIM-BENCH v0.1 runner — held-out benchmark for the 03E encoder.

    python tools/a7eam03e_bench.py --quick
    python tools/a7eam03e_bench.py --entities 400 --seeds 10 --epochs 6 --bootstrap 2000
    python tools/a7eam03e_bench.py --vn                     # Vietnamese, multi-byte UTF-8
    python tools/a7eam03e_bench.py --tsv path/to/pairs.tsv  # external dataset

Writes ``results/A7-EAM-03E/bench/bench_<ts>.json`` and prints a summary table.

TWIN SCREEN ONLY. This runs the host mirror, not silicon. It cannot close a gate
and cannot declare BOARD_PASS. Its job is to answer, cheaply and before any
bitstream is built, whether training moves *held-out* ranking above the untrained
seed-only encoder — a question the three-string smoke test cannot ask because it
has no held-out data at all.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO))

from python.eam import eam03e_bench as B  # noqa: E402
from python.eam.eam03e_twin import LAW, golden_check  # noqa: E402

OUT_DIR = REPO / "results" / "A7-EAM-03E" / "bench"


def fmt(v, width=7, nd=4):
    if v is None:
        return "—".rjust(width)
    if isinstance(v, float):
        if v != v:
            return "nan".rjust(width)
        return f"{v:.{nd}f}".rjust(width)
    return str(v).rjust(width)


def main() -> int:
    ap = argparse.ArgumentParser(description="A7-SIM-BENCH v0.1 (twin screen)")
    ap.add_argument("--entities", type=int, default=260)
    ap.add_argument("--seeds", type=int, default=5)
    ap.add_argument("--epochs", type=int, default=6)
    ap.add_argument("--bootstrap", type=int, default=0,
                    help="paired-bootstrap rounds for delta AUC CI (0 = skip)")
    ap.add_argument("--vn", action="store_true",
                    help="Vietnamese diacritics: 2-3 UTF-8 bytes per char, so the "
                         "46-byte cap holds far fewer characters")
    ap.add_argument("--tsv", default=None, help="external a<TAB>b<TAB>label file")
    ap.add_argument("--max-rows", type=int, default=4000)
    ap.add_argument("--quick", action="store_true", help="120 entities, 2 seeds, 3 epochs")
    ap.add_argument("--no-baselines", action="store_true")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    if args.quick:
        args.entities, args.seeds, args.epochs = 120, 2, 3

    gc = golden_check()
    print(f"[twin] law {LAW} · golden {'PASS' if gc['pass'] else 'FAIL'}")
    if not gc["pass"]:
        print(f"[twin] MISMATCH {gc['mismatch']} — the twin no longer mirrors the RTL. Stopping.")
        return 2

    t0 = time.perf_counter()
    if args.tsv:
        ds = B.load_pairs_tsv(args.tsv, max_rows=args.max_rows)
    else:
        ds = B.build_name_dataset(n_entities=args.entities, seed=0, vn=args.vn)
    leak = B.assert_no_leakage(ds)
    counts = ds.counts()
    print(f"[data] {ds.name} · {ds.note}")
    print(f"[data] train {counts['train']['pairs']} pairs "
          f"({counts['train']['positive']} pos) · "
          f"dev {counts['dev']['pairs']} · test {counts['test']['pairs']} "
          f"({counts['test']['positive']} pos)")
    print(f"[data] leakage check passed · distinct strings "
          f"train {leak['train_strings']} / test {leak['test_strings']}")
    if counts["test"]["pairs"] < 40:
        print("[data] WARNING test split is tiny; every number below is noise-dominated")

    seeds = B.frozen_seeds(args.seeds)
    rows = []
    for i, sd in enumerate(seeds, start=1):
        st = time.perf_counter()
        r = B.bench_seed(ds, sd, epochs=args.epochs,
                         with_baselines=not args.no_baselines,
                         bootstrap=args.bootstrap)
        rows.append(r)
        tri = r["triplet"]
        print(f"[seed {i}/{len(seeds)}] {r['seed']} "
              f"AUC {r['untrained']['auc']:.4f} -> {r['trained']['auc']:.4f} "
              f"(delta {r['delta_auc']:+.4f}, shuffled-label control "
              f"{r['delta_auc_shuffled']:+.4f}) "
              f"trip {fmt(tri.get('trip_acc'))} "
              f"satur {r['collapse']['saturation_rate']:.2f} "
              f"rank {r['collapse']['effective_rank']}/32 "
              f"[{time.perf_counter() - st:.1f}s]")

    report = B.evaluate_gates(rows)

    print("\n=== per seed ===")
    print(f"{'seed':>12} {'AUC un':>8} {'AUC tr':>8} {'dAUC':>8} {'dAUC shuf':>10} "
          f"{'AP tr':>8} {'trip':>7} {'ties':>7} {'levels':>7} {'rank':>5}")
    for r in rows:
        print(f"{r['seed']:>12} {fmt(r['untrained']['auc'], 8)} {fmt(r['trained']['auc'], 8)} "
              f"{fmt(r['delta_auc'], 8)} {fmt(r['delta_auc_shuffled'], 10)} "
              f"{fmt(r['trained']['ap'], 8)} {fmt(r['triplet'].get('trip_acc'))} "
              f"{fmt(r['trained']['tie_mass'])} {fmt(r['trained']['levels'], 7)} "
              f"{fmt(r['collapse']['effective_rank'], 5)}")

    if not args.no_baselines:
        print("\n=== baselines (median AUC across seeds; the split is identical) ===")
        names = list(B.BASELINES)
        for nm in names:
            vals = sorted(r["baselines"][nm]["auc"] for r in rows)
            print(f"{nm:>20} {fmt(vals[len(vals) // 2], 8)}")
        med_model = sorted(r["trained"]["auc"] for r in rows)
        print(f"{'MODEL (trained)':>20} {fmt(med_model[len(med_model) // 2], 8)}")
        med_un = sorted(r["untrained"]["auc"] for r in rows)
        print(f"{'MODEL (untrained)':>20} {fmt(med_un[len(med_un) // 2], 8)}"
              "   <- the control that decides everything")

    print("\n=== gates (screen only) ===")
    for k, v in report["gates"].items():
        mark = "PASS" if v.get("pass") else "FAIL"
        detail = {kk: vv for kk, vv in v.items() if kk != "pass"}
        print(f"  [{mark}] {k}  {detail}")
    print(f"\nscreen verdict: {report['screen_verdict']}")
    print(f"authority: {report['authority']}")

    c0 = rows[0]["collapse"]
    if c0.get("defect_quirk2_active"):
        print("\n[note] quirk 2 is still active: h is never negative "
              f"(negativity_rate {c0['negativity_rate']}), saturation "
              f"{c0['saturation_rate']:.2f}, effective rank {c0['effective_rank']}/32. "
              "Numbers above characterise the defect as much as the architecture.")

    rec = {
        "bench_id": B.BENCH_ID,
        "law": LAW,
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "twin_golden": gc["pass"],
        "authority": "TWIN SCREEN ONLY — not silicon evidence, not BOARD_PASS",
        "dataset": {"name": ds.name, "note": ds.note, "counts": counts, "leakage": leak,
                    "epochs": args.epochs, "vn": bool(args.vn), "tsv": args.tsv},
        "seeds": [f"0x{s:08X}" for s in seeds],
        "seed_rule": f"SHA256('{B.BENCH_ID}|i')[:4] for i<n-1, plus 0x22222222",
        "runs": rows,
        "report": report,
        "wall_seconds": round(time.perf_counter() - t0, 1),
    }
    out = Path(args.out) if args.out else (
        OUT_DIR / f"bench_{datetime.now().strftime('%Y%m%dT%H%M%S')}.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(f"\nwrote {out}  ({rec['wall_seconds']}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
