"""Authority table for the S3 decay sweep, and the locked lexicographic choice.

Columns and the selection rule are fixed by the operator instruction, not by the
data: shift is chosen on (1) stability 11/11, (2) no inversion 11/11,
(3) M_cos pass count, (4) worst-seed dAUC, (5) median dAUC. Explicitly NOT on
largest M_L1, because the current evidence shows radial magnitude can flatter L1
while angular geometry is still wrong.
"""
from __future__ import annotations

import json
import statistics as st
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "results" / "A7-EAM-03E"

SOURCES = [
    ("none", BASE / "A02_L" / "triplet_twin_sweep.json"),
    ("6", BASE / "A02_L_S3" / "sh6" / "triplet_twin_sweep.json"),
    ("5", BASE / "A02_L_S3" / "sh5" / "triplet_twin_sweep.json"),
    ("4", BASE / "A02_L_S3" / "sh4" / "triplet_twin_sweep.json"),
    ("3", BASE / "A02_L_S3" / "triplet_twin_sweep.json"),
]


def row(tag: str, path: Path) -> dict | None:
    if not path.exists():
        return None
    runs = json.load(path.open(encoding="utf-8"))["runs"]
    last = [r["series"][-1] for r in runs]
    ml = [x["M_L1"] for x in last]
    mc = [x["M_cos"] for x in last]
    ai = [r["verdict"]["auc_init"] for r in runs]
    af = [r["verdict"]["auc_final"] for r in runs]
    d = [b - a for a, b in zip(ai, af)]
    rk = [x["effective_rank"] for x in last]
    sa = [x["saturation_rate"] for x in last]
    wh = [x["Wh_l1"] for x in last]
    uq = [x["unique_d1_count"] for x in last]
    return {
        "shift": tag, "n": len(runs),
        "worst_M_L1": min(ml), "median_M_L1": st.median(ml),
        "worst_M_cos": min(mc), "median_M_cos": st.median(mc),
        "M_cos_pass": sum(1 for v in mc if v >= 0),
        "AUC_init_med": st.median(ai), "AUC_post_med": st.median(af),
        "dAUC_worst": min(d), "dAUC_median": st.median(d),
        "dAUC_pos": sum(1 for v in d if v > 0),
        "rank_min": min(rk), "rank_med": st.median(rk),
        "sat_max": max(sa), "Wh_l1_med": st.median(wh),
        "uniq_d1_min": min(uq),
        # gates
        # explicit None tests: `x or default` would read a perfect
        # saturation_rate of 0.0 as the default, since 0.0 is falsy
        "stability_all": sum(
            1 for x in last
            if x["effective_rank"] is not None and x["effective_rank"] >= 8
            and x["saturation_rate"] is not None and x["saturation_rate"] < 0.5
            and x["unique_d1_count"] > 1),
        "no_inversion_all": sum(1 for v in ml if v >= 0),
    }


def main() -> int:
    rows = [r for r in (row(t, p) for t, p in SOURCES) if r]
    hdr = (f"{'shift':>6}{'stab':>6}{'noinv':>6}{'Mcos+':>6}"
           f"{'wMcos':>8}{'medMcos':>9}{'wML1':>11}{'medML1':>10}"
           f"{'AUCi':>7}{'AUCp':>7}{'wdAUC':>8}{'medAUC':>8}{'dAUC+':>6}"
           f"{'rankmin':>8}{'satmax':>8}{'Wh_l1':>8}{'uq':>4}")
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        print(f"{r['shift']:>6}{r['stability_all']:>4}/11{r['no_inversion_all']:>4}/11"
              f"{r['M_cos_pass']:>4}/11"
              f"{r['worst_M_cos']:>8.3f}{r['median_M_cos']:>9.3f}"
              f"{r['worst_M_L1']:>11.2f}{r['median_M_L1']:>10.2f}"
              f"{r['AUC_init_med']:>7.3f}{r['AUC_post_med']:>7.3f}"
              f"{r['dAUC_worst']:>8.3f}{r['dAUC_median']:>8.3f}{r['dAUC_pos']:>4}/11"
              f"{r['rank_min']:>8}{r['sat_max']:>8.3f}{r['Wh_l1_med']:>8.0f}"
              f"{r['uniq_d1_min']:>4}")

    # locked lexicographic selection
    cand = [r for r in rows if r["shift"] != "none"]
    key = lambda r: (r["stability_all"], r["no_inversion_all"], r["M_cos_pass"],
                     r["dAUC_worst"], r["dAUC_median"])
    ranked = sorted(cand, key=key, reverse=True)
    print()
    print("lexicographic order (stability, no-inversion, M_cos pass, worst dAUC, median dAUC):")
    for i, r in enumerate(ranked):
        print(f"  {i+1}. shift {r['shift']:>4}  key = "
              f"({r['stability_all']}/11, {r['no_inversion_all']}/11, {r['M_cos_pass']}/11, "
              f"{r['dAUC_worst']:+.3f}, {r['dAUC_median']:+.3f})")
    best, second = ranked[0], ranked[1]
    print()
    print(f"CHOSEN  : shift {best['shift']}")
    print(f"RUNNERUP: shift {second['shift']}")
    gap = tuple(a - b for a, b in zip(key(best), key(second)))
    print(f"gap     : {gap}")

    out = BASE / "A02_L_S3" / "authority_table.json"
    out.write_text(json.dumps({"rows": rows, "chosen": best["shift"],
                               "runnerup": second["shift"],
                               "criterion": ["stability_all", "no_inversion_all",
                                             "M_cos_pass", "dAUC_worst",
                                             "dAUC_median"]}, indent=2),
                   encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
