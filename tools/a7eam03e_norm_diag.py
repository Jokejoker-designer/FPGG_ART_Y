"""Is the L1 margin being bought with radial scale?

Runs the operator-specified diagnostic that must precede any L2 normalization
experiment. For each held-out (A, P, N) on a trained encoder, log

    norm_A, norm_P, norm_N
    rP = norm_P / norm_A          (roadmap section 7 convention)
    rN = norm_N / norm_A
    M_L1  = d(A,N) - d(A,P)
    M_cos = cos(A,P) - cos(A,N)

then split the samples into

    AGREE     sign(M_L1) == sign(M_cos)
    DISAGREE  sign(M_L1) != sign(M_cos)

and ask whether DISAGREE carries systematic norm asymmetry. If it does, the L1
ordering is being carried by radial magnitude rather than by angular structure,
and normalization becomes a falsification experiment with a stated cause rather
than a hopeful tweak. If it does not, L2 stays closed.

Base law: triplet hinge + S3 decay >>3 on the signed state update. That is the
current standing candidate; byte attribution was tested and made every seed
worse, so it is not part of the base.

Evidence class: REFERENCE MODEL.
"""
from __future__ import annotations

import argparse
import json
import math
import statistics as st
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import a7eam03e_a02l_twin as a02l  # noqa: E402
import a7eam03e_stability as stab  # noqa: E402
import python.eam.eam03e_twin as tw  # noqa: E402
from python.eam.eam03e_bench import (  # noqa: E402
    Dataset,
    assert_no_leakage,
    build_name_dataset,
    group_split,
    spearman,
)
from python.eam.eam03e_twin import golden_check  # noqa: E402

# Chosen to span the M_cos outcome range measured at 100k on the base law, so the
# diagnostic is not run only where it is flattering.
SEEDS = [
    (0x11111111, "M_cos strongly positive (+0.246)"),
    (0xAE7C9805, "M_cos near zero (-0.009)"),
    (0xFB8CACAA, "M_cos strongly negative (-0.274)"),
]
MARGIN = 4096
DECAY_SH = 3


def norm2(h) -> float:
    return math.sqrt(sum(v * v for v in h))


def cosine(ha, hb) -> float:
    na, nb = norm2(ha), norm2(hb)
    if na == 0 or nb == 0:
        return 0.0
    return sum(a * b for a, b in zip(ha, hb)) / (na * nb)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--updates", type=int, default=100000)
    ap.add_argument("--samples", type=int, default=400)
    ap.add_argument("--shift-norm", type=int, default=None,
                    help="apply L2 radial equalisation at this band")
    ap.add_argument("--out", default="results/A7-EAM-03E/E3_NORM_DIAG")
    args = ap.parse_args()

    if not golden_check()["pass"]:
        print("REFUSE: twin drifted from A0.1-T goldens")
        return 2
    tw.h_update = stab.h_update_signed

    base = build_name_dataset(n_entities=stab.DATASET["n_entities"], seed=0)
    parts = group_split(base.train + base.dev + base.test, fracs=(0.6, 0.2, 0.2), seed=0)
    ds = Dataset(name="normdiag", train=parts["train"], dev=parts["dev"], test=parts["test"])
    assert_no_leakage(ds)
    train_trip = a02l.build_triplets(ds.train, seed=0)
    # The test split alone yields only ~35 triplets, too thin for a
    # distributional question. dev and test are both disjoint from train by
    # group_split and assert_no_leakage, and dev is not used for tuning anywhere
    # in this program, so both are legitimate held-out material here. Several
    # independent negatives per positive expand the sample without reusing a
    # positive pair.
    held_out = ds.dev + ds.test
    eval_trip = []
    for k in range(1, 6):
        eval_trip += a02l.build_triplets(held_out, seed=100 + k)
        if len(eval_trip) >= args.samples:
            break
    eval_trip = eval_trip[:args.samples]
    print(f"train triplets {len(train_trip)}   eval triplets {len(eval_trip)} "
          f"(held-out = dev + test)")

    out = {"phase": "E3 norm/radial diagnostic before L2",
           "law": "triplet hinge + S3 >>3 on signed h",
           "evidence_class": "REFERENCE_MODEL",
           "updates": args.updates, "margin": MARGIN, "decay_sh": DECAY_SH, "shift_norm": args.shift_norm,
           "convention": "rP = norm_P/norm_A, rN = norm_N/norm_A",
           "seeds": [], "ts": datetime.now(timezone.utc).isoformat()}

    for seed, note in SEEDS:
        t = a02l.TripletTwin(seed)
        t.wh_decay_sh = DECAY_SH
        t.shift_norm_band = args.shift_norm
        t.mode(learn=True, freeze=False)
        i = 0
        while t.update_count < args.updates:
            a, p, n = train_trip[i % len(train_trip)]
            i += 1
            t.triplet(a, p, n, MARGIN)
        t.teacher_off()

        rows = []
        for a, p, n in eval_trip:
            ha = t._fwd_text(a).h_final
            hp = t._fwd_text(p).h_final
            hn = t._fwd_text(n).h_final
            d_pos = a02l.TripletTwin._d1(ha, hp)
            d_neg = a02l.TripletTwin._d1(ha, hn)
            na, np_, nn = norm2(ha), norm2(hp), norm2(hn)
            m_l1 = d_neg - d_pos
            m_cos = cosine(ha, hp) - cosine(ha, hn)
            rows.append({
                "m_l1": m_l1, "m_cos": m_cos,
                "norm_A": na, "norm_P": np_, "norm_N": nn,
                "rP": np_ / na if na else 0.0,
                "rN": nn / na if na else 0.0,
            })

        def sgn(x): return (x > 0) - (x < 0)
        agree = [r for r in rows if sgn(r["m_l1"]) == sgn(r["m_cos"]) and r["m_l1"] != 0]
        dis = [r for r in rows if sgn(r["m_l1"]) != sgn(r["m_cos"]) and r["m_l1"] != 0]

        def block(g, label):
            if not g:
                return {"label": label, "n": 0}
            asym = [r["rP"] - r["rN"] for r in g]
            return {
                "label": label, "n": len(g),
                "frac": round(len(g) / max(1, len(rows)), 4),
                "mean_rP": round(st.fmean(r["rP"] for r in g), 4),
                "mean_rN": round(st.fmean(r["rN"] for r in g), 4),
                "mean_rP_minus_rN": round(st.fmean(asym), 4),
                "median_abs_asym": round(st.median(abs(x) for x in asym), 4),
                "mean_M_L1": round(st.fmean(r["m_l1"] for r in g), 2),
                "mean_M_cos": round(st.fmean(r["m_cos"] for r in g), 4),
            }

        ba, bd = block(agree, "AGREE"), block(dis, "DISAGREE")
        # does the L1 margin track radial asymmetry rather than angle?
        rho_l1_asym = spearman([r["m_l1"] for r in rows],
                               [r["rP"] - r["rN"] for r in rows])
        rho_cos_asym = spearman([r["m_cos"] for r in rows],
                                [r["rP"] - r["rN"] for r in rows])
        rec = {"seed": f"0x{seed:08X}", "note": note,
               "samples": len(rows), "agree": ba, "disagree": bd,
               "spearman_M_L1_vs_normAsym": round(rho_l1_asym, 4),
               "spearman_M_cos_vs_normAsym": round(rho_cos_asym, 4)}
        out["seeds"].append(rec)

        print(f"\n=== 0x{seed:08X}  {note} ===")
        print(f"  samples {len(rows)}   AGREE {ba['n']} ({ba.get('frac')})   "
              f"DISAGREE {bd['n']} ({bd.get('frac')})")
        for b in (ba, bd):
            if b["n"]:
                print(f"    {b['label']:<9} mean rP {b['mean_rP']:>7.4f}  "
                      f"mean rN {b['mean_rN']:>7.4f}  "
                      f"mean(rP-rN) {b['mean_rP_minus_rN']:>+8.4f}  "
                      f"median|asym| {b['median_abs_asym']:>7.4f}  "
                      f"M_L1 {b['mean_M_L1']:>9.2f}  M_cos {b['mean_M_cos']:>+8.4f}")
        print(f"    spearman(M_L1 , rP-rN) = {rho_l1_asym:+.4f}")
        print(f"    spearman(M_cos, rP-rN) = {rho_cos_asym:+.4f}")

    dst = ROOT / args.out
    dst.mkdir(parents=True, exist_ok=True)
    p = dst / "norm_diagnostic.json"
    p.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print()
    print(p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
