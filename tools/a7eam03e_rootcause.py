"""Phase S root-cause diagnostic — why the A0.1-T encoder state collapses.

Two competing hypotheses for the collapse measured by
``results/A7-EAM-03E/A02_STABILITY/stability_sweep.json``:

  H1  recurrent scale runaway: Wh grows, acc overflows, h saturates.
  H2  arithmetic signedness defect in ``h_update``: the 24-bit concatenation
      ``{{8{e[7]}}, e, 8'd0}`` is unsigned in SystemVerilog, so ``acc + concat``
      is an unsigned add and ``>>> E3_SH`` degrades to a logical shift. Any
      negative accumulator wraps to a near-2^24 value and rails h at 32767.
      Under H2 the state can never be negative and collapse needs no runaway.

H1 predicts Wh_l1 and max_abs_acc grow with update count.
H2 predicts negativity_rate == 0 always, high saturation at update 0, and that
restoring signed arithmetic removes the rail without touching Wh at all.

This script does NOT modify the A0.1-T law. The signed variant is an ablation on
the reference model only, used to falsify one hypothesis. Any real change would
need a new law id and its own contract.
"""
from __future__ import annotations

import json
import statistics
import sys
from datetime import datetime, timezone
from operator import mul
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.eam.eam03e_bench import (  # noqa: E402
    Dataset,
    assert_no_leakage,
    auc_midrank,
    build_name_dataset,
    collapse_report,
    group_split,
)
from python.eam.eam03e_twin import (  # noqa: E402
    E3_D,
    E3_SH,
    LAW,
    WH_SIZE,
    Eam03eTwin,
    sat16,
)

PROBE_STRINGS = ["ALPHA", "BETA.", "OMEGA", "Nguyen Van An", "Tran Thi Mai"]
SEEDS = [0x11111111, 0x22222222, 0xAE7C9805]


# --------------------------------------------------------------------------- #
# instrumented forward: exact signed acc, both h rules side by side
# --------------------------------------------------------------------------- #

def h_update_asis(acc_k: int, e_k: int) -> int:
    """Bit-exact copy of the shipped rule (unsigned concat, logical shift)."""
    concat24 = ((e_k & 0xFFFF) << 8) & 0xFFFFFF
    v = (acc_k + concat24) & 0xFFFFFFFF
    return sat16(v >> E3_SH)


def h_update_signed(acc_k: int, e_k: int) -> int:
    """Ablation: what the RTL comment intends — signed add, arithmetic shift."""
    v = acc_k + (e_k << 8)
    return sat16(v >> E3_SH if v >= 0 else -((-v + (1 << E3_SH) - 1) >> E3_SH))


def trace_forward(t: Eam03eTwin, text: str, rule) -> dict:
    """Forward one string, recording the exact signed acc before any masking."""
    seq = list(text.encode("utf-8"))
    h = [0] * E3_D
    e_ra = t.e_ra
    neg_acc = 0
    cells = 0
    railed_from_neg = 0
    railed_total = 0
    acc_min = 0
    per_token = []

    for b in seq:
        base = b * E3_D
        e_lat = [t.E[e_ra]] + [t.E[base + (j - 1)] for j in range(1, E3_D)]
        e_ra = base + E3_D - 1
        acc = [sum(map(mul, t.Wh[i:i + E3_D], h)) for i in range(0, WH_SIZE, E3_D)]
        nh = [rule(acc[k], e_lat[k]) for k in range(E3_D)]

        for k in range(E3_D):
            cells += 1
            if acc[k] < 0:
                neg_acc += 1
                if nh[k] == 32767:
                    railed_from_neg += 1
            if nh[k] == 32767:
                railed_total += 1
            if acc[k] < acc_min:
                acc_min = acc[k]

        h = nh
        per_token.append({
            "byte": b,
            "railed": sum(1 for v in h if v == 32767),
            "negative": sum(1 for v in h if v < 0),
            "max_abs": max(abs(v) for v in h),
        })

    return {
        "text": text,
        "tokens": len(seq),
        "cells": cells,
        "acc_negative_cells": neg_acc,
        "acc_negative_rate": round(neg_acc / cells, 4) if cells else 0.0,
        "acc_min": acc_min,
        "railed_cells": railed_total,
        "rail_rate": round(railed_total / cells, 4) if cells else 0.0,
        "railed_caused_by_negative_acc": railed_from_neg,
        "share_of_rails_from_negative_acc": (
            round(railed_from_neg / railed_total, 4) if railed_total else None),
        "h_final_railed": sum(1 for v in h if v == 32767),
        "h_final_negative": sum(1 for v in h if v < 0),
        "per_token": per_token,
    }


# --------------------------------------------------------------------------- #
# ablation: whole-encoder behaviour under each rule
# --------------------------------------------------------------------------- #

class SignedTwin(Eam03eTwin):
    """Reference-model ablation only. Not a law. Not for RTL."""

    def _forward(self, seq, text):  # type: ignore[override]
        import python.eam.eam03e_twin as tw
        keep = tw.h_update
        tw.h_update = h_update_signed
        try:
            return super()._forward(seq, text)
        finally:
            tw.h_update = keep


def encoder_block(twin: Eam03eTwin, rows) -> dict:
    twin.mode(learn=False, freeze=True)
    scores, labels, d1s = [], [], []
    for p in rows:
        tr = twin.measure(p.a, p.b, p.same)
        scores.append(-float(tr.d1))
        labels.append(1 if p.same else 0)
        d1s.append(tr.d1)
    col = collapse_report(twin, rows, limit=300)
    return {
        "auc": round(auc_midrank(scores, labels), 6),
        "unique_d1": len(set(d1s)),
        "d1_median": statistics.median(d1s),
        "saturation_rate": col.get("saturation_rate"),
        "negativity_rate": col.get("negativity_rate"),
        "effective_rank": col.get("effective_rank"),
        "spectrum_share_top1": col.get("spectrum_share_top1"),
    }


def main() -> int:
    base = build_name_dataset(n_entities=260, seed=0)
    parts = group_split(base.train + base.dev + base.test, fracs=(0.6, 0.2, 0.2), seed=0)
    ds = Dataset(name="rootcause", train=parts["train"], dev=parts["dev"], test=parts["test"])
    assert_no_leakage(ds)
    eval_rows = ds.test[:400]
    train_rows = ds.train

    out = {
        "phase": "A7-EAM-03E-A02-ROOTCAUSE-v1",
        "law_under_test": LAW,
        "law_changed": False,
        "evidence_class": "REFERENCE_MODEL",
        "hypotheses": {
            "H1": "recurrent scale runaway (Wh/acc growth drives saturation)",
            "H2": "unsigned concat + logical shift in h_update rails h from negative acc",
        },
        "traces": [],
        "ablation": [],
        "ts": datetime.now(timezone.utc).isoformat(),
    }

    print("=== per-string forward trace, untrained, shipped rule ===")
    for seed in SEEDS:
        t = Eam03eTwin(seed)
        for s in PROBE_STRINGS:
            tr = trace_forward(t, s, h_update_asis)
            tr["seed"] = f"0x{seed:08X}"
            tr["rule"] = "asis"
            out["traces"].append(tr)
            print(f"  0x{seed:08X} {s!r:18} tokens={tr['tokens']:2} "
                  f"acc<0 {tr['acc_negative_rate']:.3f}  rail {tr['rail_rate']:.3f}  "
                  f"rails from neg acc {tr['share_of_rails_from_negative_acc']}  "
                  f"acc_min {tr['acc_min']}")

    print()
    print("=== same, signed ablation ===")
    for seed in SEEDS:
        t = Eam03eTwin(seed)
        for s in PROBE_STRINGS:
            tr = trace_forward(t, s, h_update_signed)
            tr["seed"] = f"0x{seed:08X}"
            tr["rule"] = "signed"
            out["traces"].append(tr)
            print(f"  0x{seed:08X} {s!r:18} tokens={tr['tokens']:2} "
                  f"acc<0 {tr['acc_negative_rate']:.3f}  rail {tr['rail_rate']:.3f}  "
                  f"h_neg_final {tr['h_final_negative']}  acc_min {tr['acc_min']}")

    print()
    print("=== encoder-level ablation on held-out pairs ===")
    for seed in SEEDS:
        row = {"seed": f"0x{seed:08X}"}
        for name, cls in (("asis", Eam03eTwin), ("signed", SignedTwin)):
            t = cls(seed)
            row[f"{name}_untrained"] = encoder_block(t, eval_rows)
            t.mode(learn=True, freeze=False)
            for i in range(1000):
                p = train_rows[i % len(train_rows)]
                t.measure(p.a, p.b, p.same)
            row[f"{name}_trained_1000"] = encoder_block(t, eval_rows)
        out["ablation"].append(row)
        for name in ("asis", "signed"):
            u, tr = row[f"{name}_untrained"], row[f"{name}_trained_1000"]
            print(f"  0x{seed:08X} {name:7} untrained auc {u['auc']:.3f} sat {u['saturation_rate']:.3f} "
                  f"neg {u['negativity_rate']:.3f} rank {u['effective_rank']:2} uniq {u['unique_d1']:3}"
                  f"  ->  trained auc {tr['auc']:.3f} sat {tr['saturation_rate']:.3f} "
                  f"neg {tr['negativity_rate']:.3f} rank {tr['effective_rank']:2} uniq {tr['unique_d1']:3}")

    dst = ROOT / "results" / "A7-EAM-03E" / "A02_STABILITY"
    dst.mkdir(parents=True, exist_ok=True)
    path = dst / "rootcause.json"
    path.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print()
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
