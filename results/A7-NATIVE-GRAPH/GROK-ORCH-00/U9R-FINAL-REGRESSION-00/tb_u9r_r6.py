#!/usr/bin/env python3
"""U9R R6 — class predicate vs member evidence. RTL_EDIT=NO. BIT=NO.

Gold and hits in U5Q host_m10_tc.py both call type_hit on unique types.
Two facts with the same (eid,iid,rid,xid) but different object/source
collapse to one class. That is not M10 member-evidence retrieval.
"""
from __future__ import annotations

import json
from pathlib import Path

BAG = Path(__file__).resolve().parent


def class_key(f: dict) -> tuple:
    return (int(f["eid"]), int(f["iid"]), int(f["rid"]), int(f["xid"]))


def type_hit(q: dict, ck: tuple) -> bool:
    return all(int(q[k]) == int(ck[i]) for i, k in enumerate(("eid", "iid", "rid", "xid")))


def main() -> int:
    # Same TYPE_CLASS 65-like tuple; different objects/sources/negation.
    f_a = {
        "eid": 1, "iid": 1, "rid": 0, "xid": 0,
        "object": "install chiller model A",
        "source": "spec-sheet",
        "negation": 0,
        "member_id": 1001,
    }
    f_b = {
        "eid": 1, "iid": 1, "rid": 0, "xid": 0,
        "object": "do not install chiller model B",
        "source": "vendor-email",
        "negation": 1,
        "member_id": 2002,
    }
    q = {"eid": 1, "iid": 1, "rid": 0, "xid": 0, "need": "which chiller model"}
    ck_a = class_key(f_a)
    ck_b = class_key(f_b)
    same_class = ck_a == ck_b
    hit_a = type_hit(q, ck_a)
    hit_b = type_hit(q, ck_b)
    distinguished = (f_a["object"] != f_b["object"]) or (f_a["negation"] != f_b["negation"])
    class_collapses = same_class and hit_a and hit_b and distinguished
    member_lookup = False  # encoder emits {eid,iid,rid,xid}; member_ptr unused in LM stream

    out = {
        "gate": "U9R-FINAL-REGRESSION-00",
        "group": "R6",
        "same_class": same_class,
        "type_hit_both": hit_a and hit_b,
        "objects_differ": distinguished,
        "class_collapses_distinct_facts": class_collapses,
        "member_ptr_used_in_lm": member_lookup,
        "m10_scope": "CLASS_PREDICATE_CAP_ONLY",
        "result": "FAIL" if class_collapses and not member_lookup else "PASS",
        "first_divergence": "M10_MEMBER_EVIDENCE_ABSENT" if class_collapses else None,
        "bit": False,
        "program": False,
    }
    (BAG / "r6_metrics.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("R6_CLASS_KEY_A", ck_a)
    print("R6_CLASS_KEY_B", ck_b)
    print("R6_SAME_CLASS", same_class, "TYPE_HIT_BOTH", hit_a and hit_b)
    print("R6_OBJECTS_DIFFER", distinguished, "MEMBER_IN_LM", member_lookup)
    if class_collapses and not member_lookup:
        print("FIRST_DIVERGENCE M10_MEMBER_EVIDENCE_ABSENT two facts same class different object/source")
        print("M10_SCOPE CLASS_PREDICATE_CAP_ONLY not member evidence")
        print("U9R_R6_M10_GAP")
        return 7
    print("U9R_R6_M10_PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
