#!/usr/bin/env python3
"""U4A-R4: falsify P4_4k_h64 small-corpus selectivity inflation.

Same host-model path as U4A-R3. Law/profile/CAND_CAP/gold frozen.
RTL_EDIT=NO. PROGRAM=NO. U5=NO.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG_U3Q = Path(__file__).resolve().parents[1] / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from lexicon import ENTITY_CANON, ADV_SEED  # noqa: E402
from twin import extract  # noqa: E402

LAW = "qse-v1-lexicon-hdc-00"
N_TABLES = 4
N_BUCKETS = 4096
HEAD_CAP = 64
CAND_CAP = 64
POSTING_B = 16
DIR_B = 16
TH_R = 0.80  # frozen from U4A-R3; not retargeted


def keys_of(text: str) -> list[int]:
    x = extract(text)
    k0, k1, k2, k3 = x["k0"], x["k1"], x["k2"], x["k3"]
    return [k0, k1, k2, k3]


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


def build_docs():
    docs = []
    for lab, forms in ENTITY_CANON.items():
        for t in forms:
            docs.append({
                "nid": len(docs),
                "label": lab,
                "text": t,
                "ks": keys_of(t),
            })
    return docs


def index_docs(docs):
    heads = [[list() for _ in range(N_BUCKETS)] for _ in range(N_TABLES)]
    overflow = 0
    for d in docs:
        for t in range(N_TABLES):
            b = d["ks"][t] % N_BUCKETS
            if len(heads[t][b]) < HEAD_CAP:
                heads[t][b].append(d["nid"])
            else:
                overflow += 1
    return heads, overflow


def route(qks, heads, cap=CAND_CAP):
    stored, seen = [], set()
    dups = 0
    overflowed_in_path = 0
    for t in range(N_TABLES):
        b = qks[t] % N_BUCKETS
        bucket = heads[t][b]
        if len(bucket) >= HEAD_CAP:
            overflowed_in_path += 1
        for nid in bucket:
            if nid in seen:
                dups += 1
            else:
                seen.add(nid)
                stored.append(nid)
    trunc = max(0, len(stored) - cap)
    cands = stored[:cap]
    return cands, dups, trunc, overflowed_in_path


def label_of_query(text: str):
    for lab, forms in ENTITY_CANON.items():
        if text in forms or text.split()[-1:] == [lab]:
            # exact title match first
            if text in forms:
                return lab
    # known domain stems
    for lab, forms in ENTITY_CANON.items():
        if any(text == f for f in forms):
            return lab
    # "chiller" / "leak chiller" etc.
    words = set(text.split())
    # entity words from lexicon families in titles
    for lab, forms in ENTITY_CANON.items():
        canon = forms[0]
        if canon in text.split() or text == canon:
            return lab
    if "chiller" in words:
        return "chiller"
    return None


def eval_query(name, text, docs, heads, corpus_n):
    qks = keys_of(text)
    lab = label_of_query(text)
    gold = set()
    if lab is not None:
        gold = {d["nid"] for d in docs if d["label"] == lab}
    cands, dups, trunc, ovf = route(qks, heads)
    cset = set(cands)
    rel_ret = gold.intersection(cset)
    fp = cset - gold
    rec = (len(rel_ret) / len(gold)) if gold else None
    prec = (len(rel_ret) / len(cands)) if cands else (1.0 if not gold else 0.0)
    frac = len(cands) / corpus_n
    red = 1.0 - frac
    return {
        "name": name,
        "text": text,
        "label": lab,
        "k0": qks[0], "k1": qks[1], "k2": qks[2], "k3": qks[3],
        "crc_used_as_route": False,
        "candidate_count": len(cands),
        "candidate_fraction_of_corpus": frac,
        "candidate_ids": sorted(cands),
        "relevant_count": len(gold),
        "relevant_retrieved": len(rel_ret),
        "precision": prec,
        "recall": rec,
        "false_positive_count": len(fp),
        "overflow_count": ovf,
        "dedup_count": dups,
        "trunc_count": trunc,
        "bytes_query": len(cands) * POSTING_B + N_TABLES * DIR_B,
        "reduction_ratio": red,
        "returns_entire_corpus": len(cands) >= corpus_n,
    }


def jaccard(a, b):
    sa, sb = set(a), set(b)
    u = sa | sb
    if not u:
        return 1.0
    return len(sa & sb) / len(u)


def main():
    bag = Path(__file__).resolve().parent
    docs = build_docs()
    heads, idx_ovf = index_docs(docs)
    corpus_n = len(docs)
    queries = [
        ("known_domain", "chiller"),
        ("paraphrase", "water chiller"),
        ("same_entity_diff_intent", "leak chiller"),
        ("unrelated_payroll", "payroll tax form"),
        ("unrelated_soccer", "soccer match score"),
        ("adversarial", adv0()),
    ]
    rows = [eval_query(n, t, docs, heads, corpus_n) for n, t in queries]
    pairs = []
    for i in range(len(rows)):
        for j in range(i + 1, len(rows)):
            pairs.append({
                "a": rows[i]["name"],
                "b": rows[j]["name"],
                "jaccard": jaccard(rows[i]["candidate_ids"], rows[j]["candidate_ids"]),
                "unrelated_pair": rows[i]["label"] is None and rows[j]["label"] is None,
            })

    rel_rows = [r for r in rows if r["label"] is not None]
    unr_rows = [r for r in rows if r["label"] is None]
    rel_recalls = [r["recall"] for r in rel_rows if r["recall"] is not None]
    unr_entire = [r["returns_entire_corpus"] for r in unr_rows]
    unr_red = [r["reduction_ratio"] for r in unr_rows]
    unr_pairs = [p for p in pairs if p["unrelated_pair"]]
    near_full = sum(1 for r in rows if r["candidate_count"] >= corpus_n - 1)

    fails = []
    if any(r < TH_R for r in rel_recalls):
        fails.append({"id": "RETRIEVAL_RECALL_FAIL", "detail": rel_recalls})
    if any(unr_entire):
        fails.append({"id": "UNRELATED_FULL_CORPUS", "detail": [r["name"] for r in unr_rows if r["returns_entire_corpus"]]})
    if any(x <= 0 for x in unr_red):
        fails.append({"id": "REDUCTION_NOT_POSITIVE", "detail": unr_red})
    if unr_pairs and all(p["jaccard"] >= 1.0 - 1e-12 for p in unr_pairs):
        fails.append({"id": "UNRELATED_SETS_IDENTICAL", "detail": unr_pairs})
    if near_full == len(rows):
        fails.append({"id": "ROUTER_SELECTIVITY_FAIL", "detail": "candidate_count ~= corpus_size for all queries"})

    selectivity_fail = (
        (near_full >= (len(rows) * 3 + 3) // 4)
        or (all(r["candidate_fraction_of_corpus"] >= 0.99 for r in rows))
    )
    if selectivity_fail and not any(f["id"] == "ROUTER_SELECTIVITY_FAIL" for f in fails):
        fails.append({"id": "ROUTER_SELECTIVITY_FAIL", "detail": "most/all queries admit ~entire corpus"})

    verdict = "FAIL" if fails else "PASS"
    first = fails[0]["id"] if fails else None
    out = {
        "gate": "U4A-R4-SELECTIVITY-FALSIFIER-00",
        "law": LAW,
        "profile": "P4_4k_h64",
        "cand_cap": CAND_CAP,
        "corpus_size": corpus_n,
        "index_overflow_posts": idx_ovf,
        "gold": "independent ENTITY_CANON labels",
        "relevant_eq_union": False,
        "crc_as_route_key": False,
        "queries": rows,
        "pairwise_jaccard": pairs,
        "relevant_mean_recall": sum(rel_recalls) / len(rel_recalls) if rel_recalls else None,
        "unrelated_mean_reduction": sum(unr_red) / len(unr_red) if unr_red else None,
        "unrelated_mean_precision": sum(r["precision"] for r in unr_rows) / len(unr_rows) if unr_rows else None,
        "fails": fails,
        "verdict": verdict,
        "first_divergence": first,
        "u4a_r3_quality_invalidated": any(f["id"] == "ROUTER_SELECTIVITY_FAIL" for f in fails),
    }
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("CORPUS", corpus_n)
    for r in rows:
        print(
            r["name"], "n", r["candidate_count"], "frac", round(r["candidate_fraction_of_corpus"], 3),
            "rec", r["recall"], "prec", round(r["precision"], 3), "red", round(r["reduction_ratio"], 3),
            "fp", r["false_positive_count"],
        )
    print("JACCARD_UNRELATED", [p for p in pairs if p["unrelated_pair"]])
    print("VERDICT", verdict, "FIRST", first)
    if fails:
        print("U4A_R4_FAIL")
        raise SystemExit(2)
    print("U4A_R4_PASS")


if __name__ == "__main__":
    main()
