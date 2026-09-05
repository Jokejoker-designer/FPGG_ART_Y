#!/usr/bin/env python3
"""U4A-R5: table ablation. Do NOT skip key==0. RTL_EDIT=NO."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG_U3Q = Path(__file__).resolve().parents[1] / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from lexicon import ENTITY_CANON, ADV_SEED  # noqa: E402
from twin import extract  # noqa: E402

N_BUCKETS = 4096
HEAD_CAP = 64
CAND_CAP = 64
CFGS = {
    "T0": [0], "T1": [1], "T2": [2], "T3": [3],
    "T01": [0, 1], "T02": [0, 2], "T03": [0, 3],
    "T12": [1, 2], "T13": [1, 3], "T23": [2, 3],
    "ALL4": [0, 1, 2, 3],
}


def keys_of(text: str):
    x = extract(text)
    return {
        "k": [x["k0"], x["k1"], x["k2"], x["k3"]],
        "entity_id": x["entity_id"],
        "intent_id": x["intent_id"],
        "relation_id": x["relation_id"],
        "context_id": x["context_id"],
        "entity_cue": x["entity_cue"],
        "intent_cue": x["intent_cue"],
    }


def adv0() -> str:
    s = ADV_SEED
    ws = []
    for _w in range(2):
        chars = []
        for _k in range(5):
            s = (s * 1103515245 + 12345) & 0x7FFFFFFF
            chars.append(chr(ord("a") + (s % 26)))
        ws.append("".join(chars))
    return " ".join(ws)


def label_of_query(text: str):
    for lab, forms in ENTITY_CANON.items():
        if text in forms:
            return lab
    if "chiller" in text.split():
        return "chiller"
    return None


def build_docs():
    docs = []
    for lab, forms in ENTITY_CANON.items():
        for t in forms:
            info = keys_of(t)
            docs.append({"nid": len(docs), "label": lab, "text": t, **info})
    return docs


def index_heads(docs):
    heads = [[list() for _ in range(N_BUCKETS)] for _ in range(4)]
    for d in docs:
        for t in range(4):
            b = d["k"][t] % N_BUCKETS
            if len(heads[t][b]) < HEAD_CAP:
                heads[t][b].append(d["nid"])
    return heads


def route(qks, heads, tables):
    stored, seen = [], set()
    buckets = []
    occ = []
    zero_used = []
    for t in tables:
        b = qks[t] % N_BUCKETS
        buckets.append({"table": t, "bucket": b, "occupancy": len(heads[t][b])})
        occ.append(len(heads[t][b]))
        zero_used.append(qks[t] == 0)
        for nid in heads[t][b]:
            if nid not in seen:
                seen.add(nid)
                stored.append(nid)
    return stored[:CAND_CAP], buckets, zero_used


def eval_one(name, text, docs, heads, tables):
    info = keys_of(text)
    qks = info["k"]
    lab = label_of_query(text)
    gold = {d["nid"] for d in docs if d["label"] == lab} if lab else set()
    cands, buckets, zero_used = route(qks, heads, tables)
    cset = set(cands)
    rel = gold.intersection(cset)
    n = len(docs)
    rec = (len(rel) / len(gold)) if gold else None
    prec = (len(rel) / len(cands)) if cands else (1.0 if not gold else 0.0)
    return {
        "query": name,
        "text": text,
        "label": lab,
        "keys": qks,
        "ids": {k: info[k] for k in ("entity_id", "intent_id", "relation_id", "context_id")},
        "cue_lo": {"entity_cue15": info["entity_cue"] & 0xFFFF, "intent_cue15": info["intent_cue"] & 0xFFFF},
        "candidate_count": len(cands),
        "candidate_ids": sorted(cands),
        "precision": prec,
        "recall": rec,
        "reduction": 1.0 - (len(cands) / n),
        "bucket_selected": buckets,
        "bucket_occupancy": [b["occupancy"] for b in buckets],
        "zero_key_used": zero_used,
        "returns_entire_corpus": len(cands) >= n,
    }


def main():
    bag = Path(__file__).resolve().parent
    docs = build_docs()
    heads = index_heads(docs)
    n = len(docs)
    b0 = [len(heads[t][0]) for t in range(4)]
    zcount = {
        "k0==0": sum(1 for d in docs if d["k"][0] == 0),
        "k1==0": sum(1 for d in docs if d["k"][1] == 0),
        "k2==0": sum(1 for d in docs if d["k"][2] == 0),
        "k3==0": sum(1 for d in docs if d["k"][3] == 0),
    }
    # ID 0 vs cue 0: cue 0 with no class hit
    cue_absent = {
        "entity_id==0": sum(1 for d in docs if d["entity_id"] == 0),
        "k2==0_and_entity_id==0": sum(1 for d in docs if d["k"][2] == 0 and d["entity_id"] == 0),
        "k2==0_and_entity_id!=0": sum(1 for d in docs if d["k"][2] == 0 and d["entity_id"] != 0),
        "k3==0_and_intent_id==0": sum(1 for d in docs if d["k"][3] == 0 and d["intent_id"] == 0),
        "k3==0_and_intent_id!=0": sum(1 for d in docs if d["k"][3] == 0 and d["intent_id"] != 0),
    }
    queries = [
        ("known_domain", "chiller"),
        ("paraphrase", "water chiller"),
        ("same_entity_diff_intent", "leak chiller"),
        ("unrelated_payroll", "payroll tax form"),
        ("unrelated_soccer", "soccer match score"),
        ("adversarial", adv0()),
    ]
    by_cfg = {}
    for cname, tables in CFGS.items():
        by_cfg[cname] = {
            "tables": tables,
            "queries": [eval_one(n_, t, docs, heads, tables) for n_, t in queries],
        }

    # Law classification (from frozen qse PREREG, not a new invention)
    law_zero = {
        "entity_id_0": "unknown / absent family (frozen qse packet law)",
        "intent_id_0": "unknown / absent family",
        "relation_id_0": "unknown / absent family",
        "context_id_0": "unknown / absent family",
        "k0_0": "both entity_id and intent_id unknown → ABSENT composite, not a family",
        "k1_0": "both relation_id and context_id unknown → ABSENT composite",
        "k2_0": "entity_cue[15:0]==0: typically no entity-class bind; theoretically a bind could XOR to 0",
        "k3_0": "intent_cue[15:0]==0: typically no intent-class bind; theoretically XOR-to-0 possible",
        "r5_did_not_skip_zero": True,
    }

    # Which single table admits all on null queries
    null_q = ["unrelated_payroll", "unrelated_soccer", "adversarial"]
    table_admits_all = {}
    for cname in ("T0", "T1", "T2", "T3", "ALL4"):
        qs = by_cfg[cname]["queries"]
        table_admits_all[cname] = {
            q["query"]: q["returns_entire_corpus"]
            for q in qs if q["query"] in null_q or True
        }

    out = {
        "gate": "U4A-R5-NULL-KEY-TABLE-ABLATION-00",
        "corpus_size": n,
        "bucket0_occupancy_per_table": {"T0": b0[0], "T1": b0[1], "T2": b0[2], "T3": b0[3]},
        "zero_key_record_counts": zcount,
        "cue_zero_vs_id_absent": cue_absent,
        "law_zero_meaning": law_zero,
        "ablations": by_cfg,
        "null_query_admits_all": {
            c: [q["query"] for q in by_cfg[c]["queries"] if q["returns_entire_corpus"]]
            for c in CFGS
        },
        "crc_as_route": False,
        "key0_skip": False,
        "rtl_edit": False,
    }
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("CORPUS", n)
    print("BUCKET0_OCC", b0)
    print("ZERO_COUNTS", zcount)
    print("CUE_VS_ID", cue_absent)
    for cname in CFGS:
        bits = []
        for q in by_cfg[cname]["queries"]:
            bits.append(f"{q['query'][:8]} n={q['candidate_count']} red={q['reduction']:.2f} z={q['zero_key_used']}")
        print(cname, " | ".join(bits))
    print("U4A_R5_MEASURE_DONE")


if __name__ == "__main__":
    main()
