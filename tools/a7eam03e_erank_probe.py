"""Is the embedding table itself collapsing?

Every law variant tried so far (pair/unsigned, pair/signed, pair/signed+Wh
clamp, triplet/signed) ends in the same place: all distances zero, one unique
d1, AUC 0.500. The one component every variant shares is E, a 256x32 table
updated by a +-1 delta broadcast to every byte of every string in the
transaction.

Hypothesis H6: the collapse lives in E, not in h and not in Wh. The broadcast
update applies an identical delta to every row touched by a transaction, so rows
that co-occur are driven together and the table loses byte-discriminability
monotonically. Prediction: the effective rank of the *used* rows of E falls
toward 1 on the same schedule as the d1 collapse, and mean pairwise row distance
falls with it.

If H6 holds, no amount of recurrence control or hinge shaping can fix this,
because the information the encoder needs is being erased at the input layer.

Evidence class: REFERENCE MODEL.
"""
from __future__ import annotations

import json
import statistics
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
    _jacobi_eigenvalues,
    build_name_dataset,
    group_split,
)
from python.eam.eam03e_twin import E3_D, golden_check  # noqa: E402

SEEDS = [0x11111111, 0xB2B49299, 0x22222222]
CHECKPOINTS = [0, 32, 64, 128, 256, 512, 1000, 2000, 5000, 10000]
MARGIN = 4096


def e_stats(E: list[int], used: set[int]) -> dict:
    """Effective rank and row diversity of the rows of E that data actually uses."""
    rows = [E[b * E3_D:(b + 1) * E3_D] for b in sorted(used)]
    n = len(rows)
    if n < 2:
        return {"rows": n}
    means = [sum(r[i] for r in rows) / n for i in range(E3_D)]
    gram = [[0.0] * E3_D for _ in range(E3_D)]
    for r in rows:
        d = [r[i] - means[i] for i in range(E3_D)]
        for i in range(E3_D):
            di = d[i]
            if di:
                gi = gram[i]
                for j in range(i, E3_D):
                    gi[j] += di * d[j]
    for i in range(E3_D):
        for j in range(i + 1, E3_D):
            gram[j][i] = gram[i][j]
    sv = [max(0.0, e) ** 0.5 for e in _jacobi_eigenvalues(gram)]
    top = sv[0] if sv else 0.0
    eff = sum(1 for s in sv if top > 0 and s > 0.01 * top)

    # mean pairwise L1 between used rows, capped for cost
    sample = rows[:64]
    dists = []
    for i in range(len(sample)):
        for j in range(i + 1, len(sample)):
            dists.append(sum(abs(sample[i][k] - sample[j][k]) for k in range(E3_D)))
    return {
        "rows": n,
        "effective_rank": eff,
        "row_l1_mean": round(statistics.fmean(dists), 1) if dists else None,
        "row_l1_min": min(dists) if dists else None,
        "identical_pairs": sum(1 for d in dists if d == 0),
        "pairs_sampled": len(dists),
        "spectrum_top1_share": round(top / sum(sv), 4) if sum(sv) else None,
    }


def main() -> int:
    if not golden_check()["pass"]:
        print("REFUSE: twin drifted")
        return 2
    tw.h_update = stab.h_update_signed

    base = build_name_dataset(n_entities=stab.DATASET["n_entities"], seed=0)
    parts = group_split(base.train + base.dev + base.test, fracs=(0.6, 0.2, 0.2), seed=0)
    ds = Dataset(name="erank", train=parts["train"], dev=parts["dev"], test=parts["test"])
    triplets = a02l.build_triplets(ds.train, seed=0)
    used = set()
    for a, p, n in triplets:
        for s in (a, p, n):
            used.update(s.encode("utf-8"))
    print(f"distinct byte rows touched by TRAIN: {len(used)}")

    out = {"phase": "A0.2-L E-table collapse probe", "hypothesis": "H6",
           "evidence_class": "REFERENCE_MODEL", "margin": MARGIN,
           "law": a02l.LAW, "seeds": [], "ts": datetime.now(timezone.utc).isoformat()}

    for seed in SEEDS:
        t = a02l.TripletTwin(seed)
        series = []
        todo = list(CHECKPOINTS)
        idx = 0
        if todo[0] == 0:
            series.append({"updates": 0, **e_stats(t.E, used)})
            todo.pop(0)
        while todo:
            target = todo[0]
            t.mode(learn=True, freeze=False)
            while t.update_count < target:
                a, p, n = triplets[idx % len(triplets)]
                idx += 1
                t.triplet(a, p, n, MARGIN)
            series.append({"updates": t.update_count, **e_stats(t.E, used)})
            todo.pop(0)
        out["seeds"].append({"seed": f"0x{seed:08X}", "series": series})

        print(f"\n=== 0x{seed:08X} ===")
        print(f"{'upd':>6}{'E rank':>8}{'row_l1_mean':>12}{'row_l1_min':>11}"
              f"{'identical':>11}{'top1share':>11}")
        for s in series:
            print(f"{s['updates']:>6}{s['effective_rank']:>8}{s['row_l1_mean']:>12}"
                  f"{s['row_l1_min']:>11}{s['identical_pairs']:>7}/{s['pairs_sampled']}"
                  f"{s['spectrum_top1_share']:>11}")

    dst = ROOT / "results" / "A7-EAM-03E" / "A02_L"
    dst.mkdir(parents=True, exist_ok=True)
    p = dst / "erank_probe.json"
    p.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print()
    print(p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
