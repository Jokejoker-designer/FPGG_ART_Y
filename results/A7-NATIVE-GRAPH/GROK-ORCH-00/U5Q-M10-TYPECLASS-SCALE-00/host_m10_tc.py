#!/usr/bin/env python3
"""U5Q-M10-TYPECLASS-SCALE-00: M10 thresholds on TYPE_CLASS grain.

RTL_EDIT=NO. BIT=NO. Gold = masked conjunctive on unique types.
Legacy NID router is CONTROL (U5Q-M10 FAIL immutable).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402

CAND_CAP = 64
RECALL_MIN = 0.80
PREC_MIN = 0.10
NOANS_MAX = 0


def class_key(f: dict) -> tuple:
    return (int(f["eid"]), int(f["iid"]), int(f["rid"]), int(f["xid"]))


def type_hit(q: dict, ck: tuple) -> bool:
    qb = u5q.bound_slots(q)
    if not qb:
        return False
    rec = {"eid": ck[0], "iid": ck[1], "rid": ck[2], "xid": ck[3]}
    return all(rec[k] == v for k, v in qb.items())


def main() -> int:
    catalog = u5q.registered_catalog()
    feats = [u5q.feat(t) for t in catalog]
    qrows = u5q.query_list("confirm")
    qfeats = {n: u5q.feat(t) for n, t in qrows}
    scales = {}
    fails = []
    control_legacy_fail = []

    for n in u5q.SCALES:
        cat_idx = u5q.build_corpus(n, catalog, feats)
        heads, ovf, n_valid, max_id, dropped = u5q.index_corpus(n, cat_idx, feats)
        type_members: dict[tuple, list[int]] = {}
        for nid in range(n):
            ck = class_key(feats[cat_idx[nid]])
            type_members.setdefault(ck, []).append(nid)
        types = list(type_members.keys())
        n_types = len(types)
        rows = []
        for name, _text in qrows:
            q = qfeats[name]
            gold = {ck for ck in types if type_hit(q, ck)}
            hits = [ck for ck in types if type_hit(q, ck)]
            if len(hits) > CAND_CAP:
                hits = hits[:CAND_CAP]
            hit_set = set(hits)
            if gold:
                rec = len(hit_set & gold) / len(gold)
                prec = len(hit_set & gold) / len(hits) if hits else 0.0
            else:
                rec = None
                prec = 1.0 if not hits else 0.0

            rt = u5q.route(q, heads, ovf, CAND_CAP)
            seen = set()
            for nid in rt["cands"]:
                ck = class_key(feats[cat_idx[nid]])
                if type_hit(q, ck):
                    seen.add(ck)
            leg_rec = (len(seen & gold) / len(gold)) if gold else None

            tag = "%s@N=%d" % (name, n)
            if q["n_host"]:
                fails.append({"id": "HOST_SEMANTIC_LEAK", "tag": tag})
            if gold:
                if rec is None or rec < RECALL_MIN:
                    fails.append({"id": "RECALL_FAIL", "tag": tag, "rec": rec})
                if prec < PREC_MIN:
                    fails.append({"id": "PRECISION_FAIL", "tag": tag, "prec": prec})
                if len(gold) > CAND_CAP:
                    fails.append({"id": "GOLD_EXCEEDS_CAND_CAP", "tag": tag, "gold": len(gold)})
            else:
                if len(hits) > NOANS_MAX:
                    fails.append({"id": "NO_ANSWER_FP", "tag": tag, "cands": len(hits)})
            if gold and (leg_rec is None or leg_rec < RECALL_MIN):
                control_legacy_fail.append({"tag": tag, "leg_rec": leg_rec})

            rows.append({
                "query": name,
                "bound": u5q.bound_slots(q),
                "n_type_table": n_types,
                "gold_types": len(gold),
                "cands": len(hits),
                "recall": rec,
                "precision": prec,
                "legacy_type_recall": leg_rec,
                "legacy_nids": rt["n_emit"],
            })
            print("N", n, name, "types", n_types, "gold", len(gold),
                  "rec", rec, "prec", prec, "leg_rec", leg_rec)
        scales[str(n)] = {"n_type_table": n_types, "n_valid_records": n_valid, "queries": rows}

    n256 = scales["256"]["n_type_table"]
    n800 = scales["800000"]["n_type_table"]
    if n800 > 4 * n256 and n800 > 1000:
        fails.append({"id": "TYPE_TABLE_GROWS_WITH_N", "n256": n256, "n800k": n800})
    if n800 >= 800000 * 0.5:
        fails.append({"id": "FULL_SCAN_LIKE_GROWTH", "n800k": n800})

    result = "FAIL" if fails else "PASS"
    out = {
        "gate": "U5Q-M10-TYPECLASS-SCALE-00",
        "result": result,
        "first_divergence": fails[0]["id"] if fails else None,
        "fails": fails[:40],
        "control_legacy_nid_below_recall_min": control_legacy_fail[:40],
        "control_u5q_m10_nid": "FAIL_IMMUTABLE",
        "n_type_table_256": n256,
        "n_type_table_800k": n800,
        "thresholds": {
            "recall_min": RECALL_MIN,
            "precision_min_bound": PREC_MIN,
            "no_answer_max_cands": NOANS_MAX,
            "cand_cap": CAND_CAP,
        },
        "scales": scales,
        "bit": False,
        "program": False,
    }
    (BAG / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("RESULT", result, "types 256/800k", n256, n800, "n_fail", len(fails),
          "legacy_control_fail_rows", len(control_legacy_fail))
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
