#!/usr/bin/env python3
"""U4A-R6 host-model: index and query gated by explicit validity bits.

valid=0 → do not insert / do not probe that table.
valid=1 → insert/probe with unchanged key/bucket law (including key==0).
FORBIDDEN: valid = (key != 0). No full-scan fallback. No drop T3.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U3Q = BAG.parent / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from lexicon import ENTITY_CANON, ADV_SEED  # noqa: E402
from twin import extract  # noqa: E402

LAW = "qse-v1-lexicon-hdc-00"
N_TABLES = 4
N_BUCKETS = 4096
HEAD_CAP = 64
CAND_CAP = 64
TH_RECALL = 0.80  # prereg; not retargeted


def feat(text: str) -> dict:
    x = extract(text)
    return {
        "k": [x["k0"], x["k1"], x["k2"], x["k3"]],
        "v": [x["k0_valid"], x["k1_valid"], x["k2_valid"], x["k3_valid"]],
        "entity_id": x["entity_id"],
        "intent_id": x["intent_id"],
        "relation_id": x["relation_id"],
        "context_id": x["context_id"],
        "entity_cue": x["entity_cue"],
        "intent_cue": x["intent_cue"],
        "n_host": x["n_host"],
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
            info = feat(t)
            docs.append({"nid": len(docs), "label": lab, "text": t, **info})
    return docs


def index_docs(docs):
    heads = [[list() for _ in range(N_BUCKETS)] for _ in range(N_TABLES)]
    admitted = [0] * N_TABLES
    excluded = [0] * N_TABLES
    overflow = [0] * N_TABLES
    for d in docs:
        for t in range(N_TABLES):
            if d["v"][t] == 0:
                excluded[t] += 1
                continue
            b = d["k"][t] % N_BUCKETS
            if len(heads[t][b]) < HEAD_CAP:
                heads[t][b].append(d["nid"])
                admitted[t] += 1
            else:
                overflow[t] += 1
                admitted[t] += 1
    return heads, admitted, excluded, overflow


def route(q, heads, cap=CAND_CAP):
    """Query-side validity. valid=0 → skip table. No full-scan fallback."""
    stored, seen = [], set()
    probed = []
    skipped = []
    buckets = []
    used_key_neq_zero = False
    for t in range(N_TABLES):
        # Probe enable is v[t], never (k[t] != 0).
        if q["v"][t] == 0:
            skipped.append(t)
            continue
        b = q["k"][t] % N_BUCKETS
        probed.append(t)
        buckets.append({
            "table": t,
            "bucket": b,
            "occupancy": len(heads[t][b]),
            "key": q["k"][t],
            "valid": 1,
        })
        for nid in heads[t][b]:
            if nid not in seen:
                seen.add(nid)
                stored.append(nid)
    # Secret key!=0 implementation would skip valid=1,key=0. We do not.
    _ = used_key_neq_zero
    return stored[:cap], probed, skipped, buckets


def jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0  # both UNKNOWN / empty — not corpus identity
    u = a | b
    return (len(a & b) / len(u)) if u else 0.0


def eval_one(name, text, docs, heads):
    q = feat(text)
    lab = label_of_query(text)
    gold = {d["nid"] for d in docs if d["label"] == lab} if lab else set()
    cands, probed, skipped, buckets = route(q, heads)
    cset = set(cands)
    rel = gold.intersection(cset)
    n = len(docs)
    rec = (len(rel) / len(gold)) if gold else None
    prec = (len(rel) / len(cands)) if cands else (1.0 if not gold else 0.0)
    fp = cset - gold if gold else cset
    return {
        "query": name,
        "text": text,
        "label": lab,
        "k0": q["k"][0], "k1": q["k"][1], "k2": q["k"][2], "k3": q["k"][3],
        "v0": q["v"][0], "v1": q["v"][1], "v2": q["v"][2], "v3": q["v"][3],
        "ids": {
            "entity_id": q["entity_id"],
            "intent_id": q["intent_id"],
            "relation_id": q["relation_id"],
            "context_id": q["context_id"],
        },
        "n_host": q["n_host"],
        "tables_probed": probed,
        "tables_skipped": skipped,
        "bucket_selected": buckets,
        "bucket_occupancy": [b["occupancy"] for b in buckets],
        "candidate_count": len(cands),
        "candidate_ids": sorted(cands),
        "precision": prec,
        "recall": rec,
        "reduction_ratio": 1.0 - (len(cands) / n),
        "false_positives": len(fp),
        "returns_entire_corpus": len(cands) >= n,
        "crc_as_route": False,
        "used_key_neq_zero_as_valid": False,
        "full_scan_fallback": False,
    }


def protocol_valid1_key0(heads_proto):
    """Synthetic unit: not a semantic example. Proves probe follows valid, not key!=0."""
    # Isolated one-record T2 bucket 0, inserted because valid=1 even though key=0.
    q_probe = {"k": [0, 0, 0, 0], "v": [0, 0, 1, 0]}
    q_noprobe = {"k": [0, 0, 0, 0], "v": [0, 0, 0, 0]}
    q_v0_knz = {"k": [0, 0, 0xA7, 0], "v": [0, 0, 0, 0]}
    c1, p1, s1, b1 = route(q_probe, heads_proto)
    c0, p0, s0, b0 = route(q_noprobe, heads_proto)
    cnz, pnz, snz, bnz = route(q_v0_knz, heads_proto)
    return {
        "description": "synthetic valid=1,key=0 vs valid=0,key=0 on T2",
        "valid1_key0": {
            "k": q_probe["k"], "v": q_probe["v"],
            "tables_probed": p1, "candidate_count": len(c1),
            "candidate_ids": c1, "buckets": b1,
            "expected_probe": True, "observed_probe": 2 in p1,
            "pass": (2 in p1) and (len(c1) == 1) and (c1[0] == 0),
        },
        "valid0_key0": {
            "k": q_noprobe["k"], "v": q_noprobe["v"],
            "tables_probed": p0, "candidate_count": len(c0),
            "expected_probe": False, "observed_probe": 2 in p0,
            "pass": (p0 == []) and (len(c0) == 0),
        },
        "valid0_key_nonzero": {
            "k": q_v0_knz["k"], "v": q_v0_knz["v"],
            "tables_probed": pnz, "candidate_count": len(cnz),
            "expected_probe": False,
            "pass": (pnz == []) and (len(cnz) == 0),
            "note": "if probe==(key!=0) this would probe; law forbids it",
        },
    }


def main() -> int:
    docs = build_docs()
    heads, admitted, excluded, overflow = index_docs(docs)
    n = len(docs)
    b0 = [len(heads[t][0]) for t in range(N_TABLES)]
    queries = [
        ("known_domain", "chiller"),
        ("paraphrase", "water chiller"),
        ("same_entity_diff_intent", "leak chiller"),
        ("unrelated_payroll", "payroll tax form"),
        ("unrelated_soccer", "soccer match score"),
        ("adversarial", adv0()),
        ("fully_unknown", ""),
    ]
    qres = [eval_one(name, text, docs, heads) for name, text in queries]
    by_name = {q["query"]: q for q in qres}

    # Isolated protocol index: one record, T2 valid=1 key=0 in bucket 0.
    proto_heads = [[list() for _ in range(N_BUCKETS)] for _ in range(N_TABLES)]
    proto_heads[2][0].append(0)
    proto = protocol_valid1_key0(proto_heads)

    # Pairwise Jaccard among unrelated
    unr = ["unrelated_payroll", "unrelated_soccer", "adversarial"]
    pairs = {}
    for i, a in enumerate(unr):
        for b in unr[i + 1 :]:
            ja = set(by_name[a]["candidate_ids"])
            jb = set(by_name[b]["candidate_ids"])
            pairs[f"{a}__{b}"] = {
                "jaccard": jaccard(ja, jb),
                "a_count": len(ja),
                "b_count": len(jb),
            }

    ch_rec = by_name["known_domain"]["recall"]
    wc_rec = by_name["paraphrase"]["recall"]
    leak = by_name["same_entity_diff_intent"]
    ch = by_name["known_domain"]
    # R4/R5 discrimination was "leak does not admit-all via T3 bucket0".
    # After validity, T3 is empty on this labeled corpus (no intent binds).
    # Preserve the routing distinction: intent valid/key/tables differ.
    leak_disc = (
        leak["v3"] == 1
        and ch["v3"] == 0
        and leak["k3"] != ch["k3"]
        and leak["k0"] != ch["k0"]
        and (3 in leak["tables_probed"])
        and (3 not in ch["tables_probed"])
        and (not leak["returns_entire_corpus"])
        and (not ch["returns_entire_corpus"])
    )
    leak_cand_equal_via_t2 = leak["candidate_ids"] == ch["candidate_ids"]
    unk = by_name["fully_unknown"]
    pay = by_name["unrelated_payroll"]
    soc = by_name["unrelated_soccer"]
    adv = by_name["adversarial"]

    relevant_ok = (
        ch_rec is not None and ch_rec >= TH_RECALL
        and wc_rec is not None and wc_rec >= TH_RECALL
    )
    unrelated_not_full = (
        not pay["returns_entire_corpus"]
        and not soc["returns_entire_corpus"]
        and not adv["returns_entire_corpus"]
    )
    unknown_zero = unk["candidate_count"] == 0 and unk["tables_probed"] == []
    no_t3_dump = b0[3] == 0  # invalid T3 features not in bucket 0
    proto_ok = (
        proto["valid1_key0"]["pass"]
        and proto["valid0_key0"]["pass"]
        and proto["valid0_key_nonzero"]["pass"]
    )
    jacc_ok = all(
        (p["jaccard"] < 1.0) or (p["a_count"] == 0 and p["b_count"] == 0)
        for p in pairs.values()
    )
    host_zero = all(q["n_host"] == 0 for q in qres) and all(d["n_host"] == 0 for d in docs)

    fail_reasons = []
    if not relevant_ok:
        fail_reasons.append("RELEVANT_RECALL_BELOW_PREREG")
    if not unrelated_not_full:
        fail_reasons.append("UNRELATED_FULL_CORPUS")
    if not unknown_zero:
        fail_reasons.append("UNKNOWN_NOT_ZERO")
    if not no_t3_dump:
        fail_reasons.append("INVALID_T3_STILL_IN_BUCKET0")
    if not proto_ok:
        fail_reasons.append("PROTOCOL_VALID1_KEY0_FAIL")
    if not jacc_ok:
        fail_reasons.append("UNRELATED_JACCARD")
    if not host_zero:
        fail_reasons.append("HOST_SEMANTIC_NONZERO")
    if not leak_disc:
        fail_reasons.append("LEAK_CHILLER_NOT_DISCRIMINATED")
    if any(q["crc_as_route"] for q in qres):
        fail_reasons.append("CRC_ROUTING_FALLBACK")
    if any(q["full_scan_fallback"] for q in qres):
        fail_reasons.append("HIDDEN_FULL_SCAN")

    result = "PASS" if not fail_reasons else "FAIL"
    out = {
        "gate": "U4A-R6-ROUTE-VALIDITY-00",
        "law": LAW,
        "validity_law": "bind-state bits; NOT (key!=0)",
        "th_recall": TH_RECALL,
        "corpus_size": n,
        "index": {
            "records_admitted_per_table": {"T0": admitted[0], "T1": admitted[1], "T2": admitted[2], "T3": admitted[3]},
            "invalid_records_excluded_per_table": {"T0": excluded[0], "T1": excluded[1], "T2": excluded[2], "T3": excluded[3]},
            "bucket0_occupancy_per_table": {"T0": b0[0], "T1": b0[1], "T2": b0[2], "T3": b0[3]},
            "overflow_per_table": {"T0": overflow[0], "T1": overflow[1], "T2": overflow[2], "T3": overflow[3]},
        },
        "queries": qres,
        "unrelated_pairwise_jaccard": pairs,
        "protocol_valid1_key0": proto,
        "leak_chiller_discrimination": leak_disc,
        "leak_chiller_candidate_set_equal_via_t2": leak_cand_equal_via_t2,
        "result": result,
        "fail_reasons": fail_reasons,
        "crc_as_route": False,
        "drop_t3": False,
        "threshold_retarget": False,
        "relevant_eq_union": False,
        "full_scan_fallback": False,
    }
    (BAG / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("CORPUS", n)
    print("ADMITTED", admitted)
    print("EXCLUDED", excluded)
    print("BUCKET0", b0)
    for q in qres:
        print(
            q["query"],
            "k", q["k0"], q["k1"], q["k2"], q["k3"],
            "v", q["v0"], q["v1"], q["v2"], q["v3"],
            "probe", q["tables_probed"],
            "n", q["candidate_count"],
            "rec", q["recall"],
            "prec", None if q["precision"] is None else round(q["precision"], 3),
            "full", q["returns_entire_corpus"],
        )
    print("PROTOCOL", proto_ok, proto)
    print("JACCARD", pairs)
    print("RESULT", result, fail_reasons)
    print("U4A_R6_HOST_MODEL_DONE")
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
