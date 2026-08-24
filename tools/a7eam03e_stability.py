"""A7-EAM-03E Phase S — long-horizon stability of the A0.1-T learning law.

Purpose: reproduce, or fail to reproduce, the reported collapse dynamic
(recurrent scale runaway -> h saturation -> effective-rank collapse -> AUC 0.5)
against UPDATE COUNT rather than epochs.

This measures only. It changes no learning law and applies no fix. Phase S is
allowed to conclude "the collapse is real" or "it is not reproducible"; both are
results.

Authority note: evidence produced here is REFERENCE MODEL evidence, not XSim and
not board. The twin is integer-exact against the frozen A0.1-T goldens (see
``golden_check``), which is what licenses its use for the long sweep.

Experiment control: ``e_ra`` persists across pairs in the RTL, so simply
evaluating perturbs the training trajectory. Evaluation therefore saves and
restores ``e_ra`` / slot buffers / mode, making a checkpoint schedule
observation-free. This is a deliberate deviation from board behaviour and is
recorded in the manifest.
"""
from __future__ import annotations

import argparse
import json
import random
import statistics
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.eam.eam03e_bench import (  # noqa: E402
    BENCH_ID,
    Dataset,
    Pair,
    assert_no_leakage,
    auc_midrank,
    average_precision,
    b3_hist_l1,
    build_name_dataset,
    collapse_report,
    frozen_seeds,
    group_split,
    spearman,
    tie_mass,
)
import python.eam.eam03e_twin as twin_mod  # noqa: E402
from python.eam.eam03e_twin import (  # noqa: E402
    E3_SH,
    LAW,
    WH_SIZE,
    Eam03eTwin,
    cosine,
    golden_check,
    sat16,
)

# --------------------------------------------------------------------------- #
# pre-registered configuration — frozen before the first run
# --------------------------------------------------------------------------- #

PHASE_ID = "A7-EAM-03E-A02-STABILITY-v1"

CHECKPOINTS = [0, 32, 64, 128, 256, 512, 1000, 2000, 5000, 10000]

# Long-horizon authority per NATIVE_AI_V1_ROADMAP.md section 5: 10k is no longer
# enough, because S3 showed short-horizon non-inversion can be transient. The
# original checkpoints are kept verbatim and only new ones appended, so every
# previously reported number stays comparable.
EXTRA_CHECKPOINTS = [20000, 50000, 100000]

DATASET = {
    "builder": "build_name_dataset",
    "n_entities": 260,
    "dataset_seed": 0,
    "split_fracs": (0.6, 0.2, 0.2),
    "split_seed": 0,
}

# 10 seeds from the published rule, last one is the known inversion case.
SEEDS = frozen_seeds(10)
# The T golden seed is not in that list and is the one the board is pinned to.
SEEDS = [0x11111111] + SEEDS

EVAL_CAP = 400          # held-out pairs scored per checkpoint
COLLAPSE_CAP = 300      # distinct strings in the state cloud


# --------------------------------------------------------------------------- #
# measurement
# --------------------------------------------------------------------------- #

@dataclass
class Frozen:
    e_ra: int
    seqA: list
    seqB: list
    learn: bool
    freeze: bool


def _freeze_state(t: Eam03eTwin) -> Frozen:
    return Frozen(t.e_ra, list(t.seqA), list(t.seqB), t.learn, t.freeze)


def _restore_state(t: Eam03eTwin, f: Frozen) -> None:
    t.e_ra = f.e_ra
    t.seqA = list(f.seqA)
    t.seqB = list(f.seqB)
    t.learn = f.learn
    t.freeze = f.freeze


def _pct(part: int, whole: int) -> float:
    return round(part / whole, 6) if whole else 0.0


def measure(t: Eam03eTwin, rows: list[Pair], write_counts: dict) -> dict:
    """Score held-out rows and gather every Phase S telemetry field."""
    saved = _freeze_state(t)
    t.mode(learn=False, freeze=True)

    d_pos: list[int] = []
    d_neg: list[int] = []
    d_order: list[int] = []
    cos_pos: list[float] = []
    cos_neg: list[float] = []
    scores: list[float] = []
    labels: list[int] = []

    h_max = 0
    h_cells = 0
    h_clipped = 0
    acc_max = 0
    acc_wrapped = 0
    forwards = 0

    for p in rows:
        tr = t.measure(p.a, p.b, p.same)
        scores.append(-float(tr.d1))
        labels.append(1 if p.same else 0)
        d_order.append(tr.d1)
        (d_pos if p.same else d_neg).append(tr.d1)
        c = cosine(tr.a.h_final, tr.b.h_final)
        (cos_pos if p.same else cos_neg).append(c)
        for ft in (tr.a, tr.b):
            forwards += 1
            h_cells += len(ft.h_final)
            h_clipped += ft.h_saturated
            m = max((abs(v) for v in ft.h_final), default=0)
            if m > h_max:
                h_max = m
            if ft.acc_max_abs > acc_max:
                acc_max = ft.acc_max_abs
            acc_wrapped += ft.acc_wrapped

    d_all = d_pos + d_neg
    col = collapse_report(t, rows, limit=COLLAPSE_CAP)
    ws = t.weight_stats()

    # Shortcut probe: if the learned distance degenerates into a bag-of-bytes
    # metric, d1 becomes a monotone function of the byte-histogram L1 distance.
    # b3_hist_l1 returns a similarity (higher = closer), so negate to compare
    # against d1 which is a distance.
    hist = [-b3_hist_l1(p.a.encode("utf-8"), p.b.encode("utf-8")) for p in rows]
    rho_hist = spearman(d_order, hist) if len(set(d_order)) > 1 else None

    def dist(vals: list[int]) -> dict:
        if not vals:
            return {"n": 0}
        s = sorted(vals)
        return {
            "n": len(s),
            "min": s[0],
            "p25": s[len(s) // 4],
            "median": s[len(s) // 2],
            "p75": s[(3 * len(s)) // 4],
            "max": s[-1],
            "mean": round(statistics.fmean(s), 2),
            "unique": len(set(s)),
        }

    m_l1 = (statistics.fmean(d_neg) - statistics.fmean(d_pos)) if d_pos and d_neg else None
    m_cos = (statistics.fmean(cos_pos) - statistics.fmean(cos_neg)) if cos_pos and cos_neg else None

    out = {
        "updates": t.update_count,
        "pairs_seen": t.pair_count,
        "weight_writes": {
            "E": write_counts.get("E", 0),
            "Wh": write_counts.get("Wh", 0),
        },
        "auc": round(auc_midrank(scores, labels), 6),
        "ap": round(average_precision(scores, labels), 6),
        "tie_mass": round(tie_mass(scores, labels), 6),
        "M_L1": round(m_l1, 3) if m_l1 is not None else None,
        "M_cos": round(m_cos, 6) if m_cos is not None else None,
        "spearman_d1_vs_hist_l1": round(rho_hist, 4) if rho_hist is not None else None,
        "d_scale_ratio_neg_over_pos": (
            round(statistics.fmean(d_neg) / statistics.fmean(d_pos), 4)
            if d_pos and d_neg and statistics.fmean(d_pos) > 0 else None),
        "unique_d1_count": len(set(d_all)),
        "d_pos": dist(d_pos),
        "d_neg": dist(d_neg),
        "effective_rank": col.get("effective_rank"),
        "saturation_rate": col.get("saturation_rate"),
        "negativity_rate": col.get("negativity_rate"),
        "spectrum_share_top1": col.get("spectrum_share_top1"),
        "max_abs_h": h_max,
        "fraction_h_clipped": _pct(h_clipped, h_cells),
        "max_abs_acc": acc_max,
        "fraction_acc_wrapped": _pct(acc_wrapped, h_cells),
        "Wh_l1": ws["Wh_sum_abs"],
        "max_abs_Wh": ws["Wh_max_abs"],
        "Wh_rail_count": ws["Wh_saturated"],
        "E_l1": ws["E_sum_abs"],
        "max_abs_E": ws["E_max_abs"],
        "E_rail_count": ws["E_saturated"],
        "forwards_scored": forwards,
    }
    _restore_state(t, saved)
    return out


# --------------------------------------------------------------------------- #
# sweep
# --------------------------------------------------------------------------- #

def h_update_signed(acc_k: int, e_k: int) -> int:
    """Ablation rule for law `eam03e-a03-signed-h-v1`: signed add, arithmetic shift."""
    return sat16((acc_k + (e_k << 8)) >> E3_SH)


# S2 pre-registered clamp set. 128 is the control: it equals the existing sat8
# rail, so it reproduces A0.3 exactly and is not a separate condition.
WH_CLAMP_SET = (128, 64, 32, 16, 8)


# Law `eam03e-a03-ungated-diff-v1`: DIFF always repels.
#
# The shipped law gates repulsion on `d1 < E3_MARG` (4096). Untrained d1 is
# around 12000, so most DIFF transactions produce no gradient at all and early
# training is a pure attraction field on a globally shared embedding table.
#
# `E3_MARG` appears exactly twice in the twin: its definition at line 59 and the
# gate at line 339. Raising it above the d1 saturation ceiling therefore removes
# the gate and changes nothing else — SAME pull, d1, dH, the projection, SignSGD
# and the signed state update are untouched. One unknown.
#
# Authority: MUST_READ_UNBLOCK_H5.md lines 13-21 and 38.
UNGATED_MARG = 0x10000   # d1 saturates at 0xFFFF, so `d1 < UNGATED_MARG` is always true


def make_decayed_twin(sh: int, clamp: int | None = None):
    """S3 on the PAIR path: `Wh -= Wh >> sh` after every write.

    Same restoring force already characterised on the triplet path in
    `results/A7-EAM-03E/A02_L_S3/`. Kept separate from `make_clamped_twin` so a
    run is either a bound or a decay, never silently both.
    """
    class DecayedTwin(Eam03eTwin):
        def _update(self, tr, hprev):  # type: ignore[override]
            super()._update(tr, hprev)
            wh = self.Wh
            for k in range(WH_SIZE):
                v = wh[k]
                if v > 0:
                    wh[k] = v - (v >> sh)
                elif v < 0:
                    nv = -v
                    wh[k] = -(nv - (nv >> sh))
            if clamp is not None:
                lo, hi = -clamp, clamp
                for k in range(WH_SIZE):
                    v = wh[k]
                    if v > hi:
                        wh[k] = hi
                    elif v < lo:
                        wh[k] = lo

    DecayedTwin.__name__ = f"DecayedTwin{sh}"
    return DecayedTwin


def make_clamped_twin(clamp: int):
    """S2: symmetric per-weight bound on Wh, applied after each SignSGD step.

    Clamping after a +-1 step is identical to a saturating update at the same
    bound, because the step size is 1 and the clamp is idempotent. Nothing else
    in the law changes: E updates, gradients, the DIFF gate and d1 are untouched.
    """
    class ClampedTwin(Eam03eTwin):
        def _update(self, tr, hprev):  # type: ignore[override]
            super()._update(tr, hprev)
            lo, hi = -clamp, clamp
            wh = self.Wh
            for k in range(len(wh)):
                v = wh[k]
                if v > hi:
                    wh[k] = hi
                elif v < lo:
                    wh[k] = lo

    ClampedTwin.__name__ = f"ClampedTwin{clamp}"
    return ClampedTwin


def sweep_seed(seed: int, train: list[Pair], eval_rows: list[Pair],
               checkpoints: list[int], order_seed: int = 0,
               cls=Eam03eTwin) -> dict:
    t = cls(seed)
    writes = {"E": 0, "Wh": 0}
    rng = random.Random(order_seed)
    order = list(train)
    rng.shuffle(order)

    series: list[dict] = []
    todo = sorted(set(checkpoints))
    if todo and todo[0] == 0:
        series.append(measure(t, eval_rows, writes))
        todo.pop(0)

    idx = 0
    t0 = time.time()
    # Roadmap section 3 hard sanity gate: under an ungated law every DIFF
    # transaction must actually push, so suppressed must be exactly 0.
    diff = {"seen": 0, "pushed": 0, "suppressed": 0}
    while todo:
        target = todo[0]
        t.mode(learn=True, freeze=False)
        while t.update_count < target:
            p = order[idx % len(order)]
            idx += 1
            tr = t.measure(p.a, p.b, p.same)
            if not p.same:
                diff["seen"] += 1
                if tr.diff_gate_open:
                    diff["pushed"] += 1
                else:
                    diff["suppressed"] += 1
            writes["E"] += tr.e_writes
            writes["Wh"] += tr.wh_writes
        series.append(measure(t, eval_rows, writes))
        todo.pop(0)

    return {
        "seed": f"0x{seed:08X}",
        "series": series,
        "train_transactions": idx,
        "diff_seen": diff["seen"],
        "diff_push_count": diff["pushed"],
        "diff_suppressed_count": diff["suppressed"],
        "seconds": round(time.time() - t0, 1),
    }


def verdict(series: list[dict]) -> dict:
    """Phase S primary gate, applied per seed."""
    init, last = series[0], series[-1]
    aucs = [s["auc"] for s in series]
    peak = max(aucs)
    ranks = [s["effective_rank"] or 0 for s in series]
    uniq = [s["unique_d1_count"] for s in series]

    checks = {
        "auc_post_gt_init": last["auc"] > init["auc"],
        "auc_not_back_to_chance": abs(last["auc"] - 0.5) > 0.02,
        "effective_rank_noncollapsed": (last["effective_rank"] or 0) >= 8,
        "saturation_below_total": (last["saturation_rate"] or 1.0) < 0.50,
        "unique_d1_gt_1": last["unique_d1_count"] > 1,
        "no_acc_runaway": last["fraction_acc_wrapped"] == 0.0,
    }
    return {
        "checks": checks,
        "pass": all(checks.values()),
        "auc_init": init["auc"],
        "auc_peak": peak,
        "auc_peak_at_updates": series[aucs.index(peak)]["updates"],
        "auc_final": last["auc"],
        "rank_init": ranks[0],
        "rank_final": ranks[-1],
        "unique_d1_init": uniq[0],
        "unique_d1_final": uniq[-1],
        "collapse_reproduced": (peak - last["auc"]) > 0.02 or (ranks[-1] < 8 <= ranks[0]),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase S long-horizon stability sweep")
    ap.add_argument("--seeds", type=int, default=len(SEEDS),
                    help="how many pre-registered seeds to run, in order")
    ap.add_argument("--max-updates", type=int, default=CHECKPOINTS[-1])
    ap.add_argument("--out", default="results/A7-EAM-03E/A02_STABILITY")
    ap.add_argument("--rule", choices=("asis", "signed"), default="asis",
                    help="'signed' runs the eam03e-a03-signed-h-v1 ablation")
    ap.add_argument("--wh-clamp", default="",
                    help="S2 experiment: comma list from the pre-registered set "
                         f"{WH_CLAMP_SET}. 128 is the control.")
    ap.add_argument("--diff-gate", choices=("gated", "ungated"), default="gated",
                    help="'ungated' = law eam03e-a03-ungated-diff-v1: DIFF always "
                         "pushes instead of only when d1 < E3_MARG")
    ap.add_argument("--wh-decay-sh", type=int, default=None,
                    help="S3 on the pair path, pre-registered shifts (6,5,4,3)")
    args = ap.parse_args()

    if args.wh_decay_sh is not None and args.wh_decay_sh not in (6, 5, 4, 3):
        print("REFUSE: decay shift not in pre-registered set (6,5,4,3)")
        return 2
    if args.wh_decay_sh is not None and args.wh_clamp:
        print("REFUSE: decay and clamp are separate experiments; pick one")
        return 2

    clamps: list[int] = []
    if args.wh_clamp:
        clamps = [int(x) for x in args.wh_clamp.split(",")]
        bad = [c for c in clamps if c not in WH_CLAMP_SET]
        if bad:
            print(f"REFUSE: clamp {bad} is not in the pre-registered set "
                  f"{WH_CLAMP_SET}; pre-register it first")
            return 2

    gc = golden_check()
    if not gc["pass"]:
        print("REFUSE: twin no longer matches A0.1-T goldens", gc["mismatch"])
        return 2

    law = LAW
    if args.rule == "signed":
        # Patched only after golden_check has validated the oracle against the
        # shipped law, so the ablation cannot mask a drifted twin.
        twin_mod.h_update = h_update_signed
        law = "eam03e-a03-signed-h-v1 (REFERENCE MODEL ABLATION, no RTL)"
    if args.diff_gate == "ungated":
        # d1 saturates at 0xFFFF, so a threshold of 0x10000 is unreachable and
        # the DIFF gate is always open. Arithmetically identical to deleting the
        # condition, with no duplicated update path to keep in sync.
        twin_mod.E3_MARG = UNGATED_MARG
        law += " + ungated DIFF (eam03e-a03-ungated-diff-v1)"

    base = build_name_dataset(n_entities=DATASET["n_entities"], seed=DATASET["dataset_seed"])
    parts = group_split(base.train + base.dev + base.test,
                        fracs=DATASET["split_fracs"], seed=DATASET["split_seed"])
    ds = Dataset(name=f"{base.name}/regrouped", train=parts["train"],
                 dev=parts["dev"], test=parts["test"], note=base.note)
    leak = assert_no_leakage(ds)

    eval_rows = ds.test[:EVAL_CAP]
    cps = [c for c in CHECKPOINTS + EXTRA_CHECKPOINTS if c <= args.max_updates]

    if args.wh_decay_sh is not None:
        conditions = [(None, make_decayed_twin(args.wh_decay_sh))]
        law += f" + S3 decay >>{args.wh_decay_sh}"
    else:
        conditions = [(c, make_clamped_twin(c)) for c in clamps] or [(None, Eam03eTwin)]

    rows = []
    for clamp, cls in conditions:
        if clamp is not None:
            print(f"--- S2 Wh clamp = +-{clamp}"
                  f"{'  (control, equals sat8 rail)' if clamp == 128 else ''} ---",
                  flush=True)
        for seed in SEEDS[:args.seeds]:
            r = sweep_seed(seed, ds.train, eval_rows, cps, cls=cls)
            r["wh_clamp"] = clamp
            r["verdict"] = verdict(r["series"])
            rows.append(r)
            v = r["verdict"]
            print(f"{r['seed']}  auc {v['auc_init']:.3f} -> peak {v['auc_peak']:.3f}"
                  f" @{v['auc_peak_at_updates']} -> final {v['auc_final']:.3f}"
                  f"  rank {v['rank_init']}->{v['rank_final']}"
                  f"  uniq_d1 {v['unique_d1_init']}->{v['unique_d1_final']}"
                  f"  {'PASS' if v['pass'] else 'FAIL'}"
                  f"{'  COLLAPSE' if v['collapse_reproduced'] else ''}"
                  f"  [{r['seconds']}s]", flush=True)

    n_pass = sum(1 for r in rows if r["verdict"]["pass"])
    n_collapse = sum(1 for r in rows if r["verdict"]["collapse_reproduced"])
    supp = sum(r.get("diff_suppressed_count", 0) for r in rows)
    seen = sum(r.get("diff_seen", 0) for r in rows)
    pushed = sum(r.get("diff_push_count", 0) for r in rows)
    sanity = {
        "diff_seen": seen, "diff_push_count": pushed,
        "diff_suppressed_count": supp,
        "gate": "diff_suppressed_count == 0",
        "pass": supp == 0 if args.diff_gate == "ungated" else None,
    }
    print()
    print(f"DIFF sanity: seen={seen} pushed={pushed} suppressed={supp}"
          + (f"  -> {'PASS' if supp == 0 else 'FAIL'}"
             if args.diff_gate == "ungated" else "  (gated law, suppression expected)"))
    rec = {
        "phase": PHASE_ID,
        "bench": BENCH_ID,
        "law": law,
        "rule": args.rule,
        "law_changed": args.rule != "asis",
        "s2_wh_clamp_preregistered_set": list(WH_CLAMP_SET),
        "s2_wh_clamp_run": clamps or None,
        "evidence_class": "REFERENCE_MODEL",
        "twin_golden": gc["pass"],
        "experiment_control": "e_ra/slots/mode saved and restored across evaluation "
                              "so the checkpoint schedule does not perturb training",
        "checkpoints_updates": cps,
        "diff_sanity": sanity,
        "dataset": {**DATASET, "counts": ds.counts(), "leakage": leak,
                    "eval_rows_used": len(eval_rows)},
        "seeds_preregistered": [f"0x{s:08X}" for s in SEEDS],
        "seeds_run": [f"0x{s:08X}" for s in SEEDS[:args.seeds]],
        "summary": {
            "seeds": len(rows),
            "stability_pass": n_pass,
            "stability_fail": len(rows) - n_pass,
            "collapse_reproduced": n_collapse,
        },
        "runs": rows,
        "ts": datetime.now(timezone.utc).isoformat(),
    }

    out = ROOT / args.out
    out.mkdir(parents=True, exist_ok=True)
    path = out / "stability_sweep.json"
    path.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print()
    print(f"seeds={len(rows)} stability_pass={n_pass} collapse_reproduced={n_collapse}")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
