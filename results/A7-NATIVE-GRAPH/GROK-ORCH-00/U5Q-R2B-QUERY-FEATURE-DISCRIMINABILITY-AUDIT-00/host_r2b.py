#!/usr/bin/env python3
"""U5Q-R2B: {k,v} discriminability of relevant vs hard-negative."""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402


def vis(f: dict) -> tuple:
    return tuple(f["k"]) + tuple(f["v"])


def class_key(f: dict) -> tuple:
    return (f["eid"], f["iid"], f["rid"], f["xid"])


def main() -> int:
    catalog = u5q.registered_catalog()
    feats = [u5q.feat(t) for t in catalog]
    qrows = u5q.query_list("confirm")
    rows = []
    any_insep = False
    for name, text in qrows:
        q = u5q.feat(text)
        rel, irrel = [], []
        for f in feats:
            (rel if u5q.is_relevant(q, f) else irrel).append(f)
        irrel_vis = {vis(f) for f in irrel}
        irrel_k = [{f["k"][t] for f in irrel} for t in range(4)]
        irrel_vm = {tuple(f["v"]) for f in irrel}
        twins = [f for f in rel if vis(f) in irrel_vis]
        same = []
        for t in range(4):
            n = sum(1 for f in rel if f["k"][t] in irrel_k[t])
            same.append(n)
        same_v = sum(1 for f in rel if tuple(f["v"]) in irrel_vm)

        by_vis_rel = defaultdict(set)
        by_vis_irr = defaultdict(set)
        for f in rel:
            by_vis_rel[vis(f)].add(class_key(f))
        for f in irrel:
            by_vis_irr[vis(f)].add(class_key(f))
        mixed_vis = [v for v in by_vis_rel if v in by_vis_irr]
        class_collision = 0
        for v in mixed_vis:
            class_collision += len(by_vis_rel[v])

        nR = len(rel)
        frac = (len(twins) / nR) if nR else 0.0
        if nR and frac > 0:
            any_insep = True
            diag = "NO_ROUTER_GEOMETRY_CAN_SEPARATE_THEM"
        elif nR and (same[0] or same[1] or same[2] or same[3]):
            diag = "PARTIAL_FIELD_COLLISION"
        elif nR:
            diag = "FEATURES_SEPARATE_AT_CLASS_GRAIN"
        else:
            diag = "NO_ANSWER"

        rows.append({
            "query": name,
            "text": text,
            "bound": u5q.bound_slots(q),
            "n_relevant_catalog": nR,
            "n_irrelevant_catalog": len(irrel),
            "n_unique_rel_class": len({class_key(f) for f in rel}),
            "n_identical_vis_twins": len(twins),
            "frac_rel_inseparable": frac,
            "n_route_keys_mixed": len(mixed_vis),
            "n_rel_class_on_mixed_vis": class_collision,
            "n_rel_same_k0_as_some_irrel": same[0],
            "n_rel_same_k1_as_some_irrel": same[1],
            "n_rel_same_k2_as_some_irrel": same[2],
            "n_rel_same_k3_as_some_irrel": same[3],
            "n_rel_same_valid_mask_as_some_irrel": same_v,
            "diagnosis": diag,
        })
        print(name, diag, "R", nR, "twins", len(twins), "frac", round(frac, 4),
              "mixed_vis", len(mixed_vis), "same_k", same)

    overall = (
        "NO_ROUTER_GEOMETRY_CAN_SEPARATE_THEM" if any_insep
        else "PARTIAL_OR_SEPARATE"
    )
    out = {
        "gate": "U5Q-R2B-QUERY-FEATURE-DISCRIMINABILITY-AUDIT-00",
        "result": "MEASURE_PASS",
        "overall_diagnosis": overall,
        "queries": rows,
        "u7a": "CLOSED",
        "u5q": "STILL_FAIL",
    }
    (BAG / "DISC.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("OVERALL", overall)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
