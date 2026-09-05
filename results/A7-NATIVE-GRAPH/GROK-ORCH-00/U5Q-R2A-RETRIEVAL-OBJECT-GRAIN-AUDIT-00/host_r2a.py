#!/usr/bin/env python3
"""U5Q-R2A: retrieval object grain. RAW nid vs TYPE_CLASS vs TYPE_TEXT."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402

CAND_CAP_REF = 64
RECALL_T = 0.80


def class_key(f: dict) -> tuple:
    return (f["eid"], f["iid"], f["rid"], f["xid"])


def route_key(f: dict) -> tuple:
    return tuple(f["k"]) + tuple(f["v"])


def multiplicity(n: int, seed_n: int, c: int) -> list[int]:
    m = [0] * c
    for i in range(min(n, seed_n)):
        m[i] += 1
    rem = max(0, n - seed_n)
    if rem:
        q, r = divmod(rem, c)
        for i in range(c):
            m[i] += q
        for i in range(r):
            m[i] += 1
    return m


def diagnose(n_raw: int, n_class: int) -> str:
    if n_raw == 0:
        return "NO_ANSWER"
    min_raw = math.ceil(RECALL_T * n_raw)
    min_cls = math.ceil(RECALL_T * n_class) if n_class else 10**9
    raw_over = min_raw > CAND_CAP_REF
    cls_fit = min_cls <= CAND_CAP_REF
    if raw_over and cls_fit:
        return "RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP"
    if raw_over and not cls_fit:
        return "BOTH_GRAINS_EXCEED_CAP"
    return "RAW_GRAIN_BUDGET_OK"


def main() -> int:
    catalog = u5q.registered_catalog()
    feats = [u5q.feat(t) for t in catalog]
    seed_n = 0
    seed_set = set(u5q.registered_seed_texts())
    for i, t in enumerate(catalog):
        if t in seed_set:
            seed_n = i + 1
        else:
            break
    qrows = u5q.query_list("confirm")
    qfeats = {name: u5q.feat(text) for name, text in qrows}

    scales = {}
    for n in u5q.SCALES:
        mult = multiplicity(n, seed_n, len(catalog))
        rows = []
        for name, text in qrows:
            q = qfeats[name]
            raw = 0
            classes = set()
            texts = set()
            routes = set()
            for i, f in enumerate(feats):
                if mult[i] == 0:
                    continue
                if not u5q.is_relevant(q, f):
                    continue
                raw += mult[i]
                classes.add(class_key(f))
                texts.add(f["text"])
                routes.add(route_key(f))
            n_cls = len(classes)
            n_txt = len(texts)
            n_rt = len(routes)
            min_raw = math.ceil(RECALL_T * raw) if raw else 0
            min_cls = math.ceil(RECALL_T * n_cls) if n_cls else 0
            min_txt = math.ceil(RECALL_T * n_txt) if n_txt else 0
            rows.append({
                "query": name,
                "text": text,
                "bound": u5q.bound_slots(q),
                "N_RELEVANT_RAW_INSTANCES": raw,
                "N_UNIQUE_TYPE_CLASS": n_cls,
                "N_UNIQUE_TYPE_TEXT": n_txt,
                "N_UNIQUE_TYPE_ROUTE": n_rt,
                "DUPLICATION_RATIO_CLASS": (raw / n_cls) if n_cls else None,
                "DUPLICATION_RATIO_TEXT": (raw / n_txt) if n_txt else None,
                "MIN_CANDS_FOR_RAW_RECALL_0.80": min_raw,
                "MIN_CANDS_FOR_CLASS_RECALL_0.80": min_cls,
                "MIN_CANDS_FOR_TEXT_RECALL_0.80": min_txt,
                "RAW_EXCEEDS_CAND_CAP64": min_raw > CAND_CAP_REF if raw else False,
                "CLASS_FITS_CAND_CAP64": (min_cls <= CAND_CAP_REF) if n_cls else True,
                "TEXT_FITS_CAND_CAP64": (min_txt <= CAND_CAP_REF) if n_txt else True,
                "diagnosis": diagnose(raw, n_cls),
            })
        scales[str(n)] = rows

    # Gate-level diagnosis from N=800000 bound queries
    d800 = [r["diagnosis"] for r in scales["800000"] if r["bound"]]
    if d800 and all(x == "RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP" for x in d800):
        overall = "RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP"
    elif any(x == "BOTH_GRAINS_EXCEED_CAP" for x in d800):
        overall = "MIXED_OR_BOTH_EXCEED"
    elif d800 and all(x == "RAW_GRAIN_BUDGET_OK" for x in d800):
        overall = "RAW_GRAIN_BUDGET_OK"
    else:
        overall = "MIXED_PER_QUERY"

    out = {
        "gate": "U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00",
        "result": "MEASURE_PASS",
        "overall_diagnosis": overall,
        "cand_cap_ref": CAND_CAP_REF,
        "recall_t": RECALL_T,
        "does_not_change": ["U5Q_FAIL", "U6_RETAINED", "U7A_CLOSED"],
        "master_object_chosen": False,
        "scales": scales,
    }
    (BAG / "GRAIN.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("OVERALL", overall)
    print("N=800000")
    for r in scales["800000"]:
        print(
            r["query"],
            "raw", r["N_RELEVANT_RAW_INSTANCES"],
            "class", r["N_UNIQUE_TYPE_CLASS"],
            "text", r["N_UNIQUE_TYPE_TEXT"],
            "dup", r["DUPLICATION_RATIO_CLASS"],
            "min_raw", r["MIN_CANDS_FOR_RAW_RECALL_0.80"],
            "min_cls", r["MIN_CANDS_FOR_CLASS_RECALL_0.80"],
            r["diagnosis"],
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
