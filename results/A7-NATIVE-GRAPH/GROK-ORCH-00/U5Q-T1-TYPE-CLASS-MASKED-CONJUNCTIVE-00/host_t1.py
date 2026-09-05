#!/usr/bin/env python3
"""U5Q-T1: TYPE_CLASS masked conjunctive retrieval. Host-model. No QSE change."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402

CAND_CAP = 64


def class_key(f: dict) -> tuple:
    return (int(f["eid"]), int(f["iid"]), int(f["rid"]), int(f["xid"]))


def ck_str(ck: tuple) -> str:
    return "%d.%d.%d.%d" % ck


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

    for n in u5q.SCALES:
        cat_idx = u5q.build_corpus(n, catalog, feats)
        heads, ovf, n_valid, max_id, dropped = u5q.index_corpus(n, cat_idx, feats)
        type_members: dict[tuple, list[int]] = {}
        for nid in range(n):
            ck = class_key(feats[cat_idx[nid]])
            type_members.setdefault(ck, []).append(nid)
        n_types = len(type_members)
        rows = []
        for name, text in qrows:
            q = qfeats[name]
            gold = {ck for ck in type_members if type_hit(q, ck)}
            # TYPE_TABLE retrieval = gold (complete class index, conjunctive)
            table_hits = sorted(gold)
            n_tab = len(table_hits)
            rec_tab = 1.0 if gold else None
            prec_tab = 1.0 if table_hits else (1.0 if not gold else 0.0)
            if gold:
                rec_tab = len(set(table_hits) & gold) / len(gold)
                prec_tab = len(set(table_hits) & gold) / len(table_hits) if table_hits else 0.0

            # LEGACY nid collapse (frozen P4, not a sweep)
            rt = u5q.route(q, heads, ovf, CAND_CAP)
            collapsed = []
            seen_ck = set()
            n_filtered = 0
            for nid in rt["cands"]:
                f = feats[cat_idx[nid]]
                ck = class_key(f)
                if not type_hit(q, ck):
                    n_filtered += 1
                    continue
                if ck in seen_ck:
                    continue
                seen_ck.add(ck)
                collapsed.append(ck)
            rec_leg = (len(seen_ck & gold) / len(gold)) if gold else None
            prec_leg = (len(seen_ck & gold) / len(seen_ck)) if seen_ck else (1.0 if not gold else 0.0)

            tag = "%s@N=%d" % (name, n)
            if q["n_host"]:
                fails.append({"id": "HOST_SEMANTIC_LEAK", "tag": tag})
            if gold:
                if rec_tab != 1.0 or prec_tab != 1.0:
                    fails.append({"id": "TYPE_TABLE_NOT_EXACT", "tag": tag, "rec": rec_tab, "prec": prec_tab})
                if n_tab > CAND_CAP:
                    fails.append({"id": "CAND_CAP_FAIL", "tag": tag, "cands": n_tab})
            else:
                if n_tab != 0:
                    fails.append({"id": "NO_ANSWER_FP", "tag": tag, "cands": n_tab})

            rows.append({
                "query": name,
                "bound": u5q.bound_slots(q),
                "n_type_table": n_types,
                "gold_types": n_tab,
                "table_cands": n_tab,
                "table_recall": rec_tab,
                "table_precision": prec_tab,
                "legacy_nids": rt["n_emit"],
                "legacy_fp_nids_filtered": n_filtered,
                "legacy_types": len(collapsed),
                "legacy_type_recall": rec_leg,
                "legacy_type_precision": prec_leg,
                "legacy_bytes": rt["bytes"],
                "provenance_members_min": min((len(type_members[ck]) for ck in gold), default=0),
                "provenance_members_max": max((len(type_members[ck]) for ck in gold), default=0),
            })
            print(
                "N", n, name,
                "types_all", n_types, "gold", n_tab,
                "leg_nid", rt["n_emit"], "leg_filt", n_filtered,
                "leg_types", len(collapsed), "leg_rec", rec_leg,
            )
        scales[str(n)] = {"n_type_table": n_types, "n_valid_records": n_valid, "queries": rows}

    # saturation: type table must not track raw N
    n256 = scales["256"]["n_type_table"]
    n800 = scales["800000"]["n_type_table"]
    if n800 > 4 * n256 and n800 > 1000:
        fails.append({"id": "TYPE_TABLE_GROWS_WITH_N", "n256": n256, "n800k": n800})

    result = "FAIL" if fails else "PASS"
    out = {
        "gate": "U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00",
        "result": result,
        "first_divergence": fails[0]["id"] if fails else None,
        "fails": fails[:40],
        "n_type_table_256": n256,
        "n_type_table_800k": n800,
        "scales": scales,
        "u5q_raw": "FAIL_IMMUTABLE",
        "u6_old_profile": "HISTORICAL_XSIM_ONLY",
        "u7a": "CLOSED",
    }
    (BAG / "TYPECLASS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("RESULT", result, "N_TYPES 256/800k", n256, n800, "n_fail", len(fails))
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
