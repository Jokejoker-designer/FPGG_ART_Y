#!/usr/bin/env python3
"""U4A-R3 router rival: FPGA qse keys + independent label gold.

Not U4A-R2 synthetic rec_keys tautology. Law qse-v1-lexicon-hdc-00 unchanged.
PROGRAM=NO. U5=NO.
"""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

BAG_U3Q = Path(__file__).resolve().parents[1] / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from lexicon import ENTITY_CANON, UNRELATED  # noqa: E402
from twin import extract  # noqa: E402

LAW = "qse-v1-lexicon-hdc-00"
N_SCALE = 800_000
MIN_COVERAGE = 0.20
TH_R16 = 0.80
TH_R64 = 0.85
CAPS = [64, 128, 192, 256, 384, 512, 1024, 2048]
POSTING_B = 16
DIR_ENTRY_B = 16


def keys_of(text: str) -> list[int]:
    x = extract(text)
    k = [x["k0"], x["k1"], x["k2"], x["k3"]]
    k += [
        (x["k0"] ^ x["k1"]) & 0xFFFF,
        (x["k2"] ^ x["k3"]) & 0xFFFF,
        (x["k0"] + x["k2"]) & 0xFFFF,
        (x["k1"] + x["k3"]) & 0xFFFF,
    ]
    return k


def build_label_docs():
    docs = []
    for lab, forms in ENTITY_CANON.items():
        for s in forms:
            ks = keys_of(s)
            docs.append({"nid": len(docs), "label": lab, "text": s, "ks": ks})
    return docs


def index_docs(docs, n_tables, n_buckets, head_cap):
    heads = [[list() for _ in range(n_buckets)] for _ in range(n_tables)]
    gold_lists = [[list() for _ in range(n_buckets)] for _ in range(n_tables)]
    overflow = 0
    covered = set()
    for d in docs:
        nid = d["nid"]
        for t in range(n_tables):
            b = d["ks"][t] % n_buckets
            gold_lists[t][b].append(nid)
            if len(heads[t][b]) < head_cap:
                heads[t][b].append(nid)
                covered.add(nid)
            else:
                overflow += 1
    occ = [len(h) for t in heads for h in t]
    occ.sort()
    return heads, {
        "overflow_posts": overflow,
        "coverage": len(covered) / max(len(docs), 1),
        "occ_max": occ[-1] if occ else 0,
        "empty_frac": sum(1 for x in occ if x == 0) / max(len(occ), 1),
        "dir_bytes": n_tables * n_buckets * DIR_ENTRY_B,
    }


def label_eval(docs, heads, n_tables, n_buckets, cap):
    recs = []
    head_hits = []
    for q in docs:
        gold = {d["nid"] for d in docs if d["label"] == q["label"] and d["nid"] != q["nid"]}
        if not gold:
            continue
        stored = []
        seen = set()
        for t in range(n_tables):
            b = q["ks"][t] % n_buckets
            for nid in heads[t][b]:
                if nid == q["nid"] or nid in seen:
                    continue
                seen.add(nid)
                stored.append(nid)
        head_hits.append(len(gold.intersection(seen)) / len(gold))
        cands = stored[:cap]
        recs.append(len(gold.intersection(cands)) / len(gold))
    return {
        "n_q": len(recs),
        "mean_recall": sum(recs) / len(recs) if recs else 0.0,
        "mean_head_hit": sum(head_hits) / len(head_hits) if head_hits else 0.0,
        "mean_bytes": (min(cap, 64) * POSTING_B + n_tables * DIR_ENTRY_B),
    }


def scale_index(n_tables, n_buckets, head_cap):
    covered = set()
    overflow = 0
    occ = [0] * (n_tables * n_buckets)
    for nid in range(N_SCALE):
        eid = 1 + (nid % 12)
        iid = 1 + (nid % 6)
        k0 = (eid << 8) | iid
        k1 = 0
        k2 = nid & 0xFFFF
        k3 = (nid >> 4) & 0xFFFF
        ks = [k0, k1, k2, k3, k0 ^ k1, k2 ^ k3, (k0 + k2) & 0xFFFF, (k1 + k3) & 0xFFFF]
        for t in range(n_tables):
            b = ks[t] % n_buckets
            idx = t * n_buckets + b
            if occ[idx] < head_cap:
                occ[idx] += 1
                covered.add(nid)
            else:
                overflow += 1
    return {
        "n": N_SCALE,
        "coverage": len(covered) / N_SCALE,
        "overflow_posts": overflow,
        "occ_max": max(occ) if occ else 0,
        "empty_frac": sum(1 for x in occ if x == 0) / max(len(occ), 1),
        "note": "occupancy only; not semantic recall",
    }


def run_profile(name, n_tables, n_buckets, head_cap, docs):
    heads, st = index_docs(docs, n_tables, n_buckets, head_cap)
    by_cap = {}
    for cap in CAPS:
        sl = []
        recs = []
        hits = []
        bytes_q = []
        for q in docs:
            gold = {d["nid"] for d in docs if d["label"] == q["label"] and d["nid"] != q["nid"]}
            if not gold:
                continue
            stored, seen = [], set()
            for t in range(n_tables):
                b = q["ks"][t] % n_buckets
                for nid in heads[t][b]:
                    if nid == q["nid"] or nid in seen:
                        continue
                    seen.add(nid)
                    stored.append(nid)
            hits.append(len(gold.intersection(seen)) / len(gold))
            cands = stored[:cap]
            recs.append(len(gold.intersection(cands)) / len(gold))
            bytes_q.append(len(cands) * POSTING_B + n_tables * DIR_ENTRY_B)
        by_cap[str(cap)] = {
            "mean_recall": sum(recs) / len(recs) if recs else 0.0,
            "mean_head_hit": sum(hits) / len(hits) if hits else 0.0,
            "mean_bytes": sum(bytes_q) / len(bytes_q) if bytes_q else 0.0,
        }
    scale = scale_index(n_tables, n_buckets, head_cap)
    rejected = scale["coverage"] < MIN_COVERAGE
    r16 = by_cap["64"]["mean_recall"] if "64" in by_cap else 0
    # use cap 16 via min(stored) — report cap 64 as proxy if 16 not in CAPS
    # add explicit 16
    return {
        "name": name,
        "n_tables": n_tables,
        "n_buckets": n_buckets,
        "head_cap": head_cap,
        "label_index": st,
        "by_cap": by_cap,
        "scale": scale,
        "rejected": rejected,
        "reject_reason": "scale_coverage" if rejected else None,
    }


def pareto(profiles):
    cands = []
    for p in profiles:
        if p["rejected"]:
            continue
        for cap in CAPS:
            b = p["by_cap"][str(cap)]
            cands.append({
                "profile": p["name"],
                "cand_cap": cap,
                "recall": b["mean_recall"],
                "bytes": b["mean_bytes"],
                "coverage_scale": p["scale"]["coverage"],
            })
    if not cands:
        return {"chosen": None, "reason": "all_rejected"}
    best = max(c["recall"] for c in cands)
    near = [c for c in cands if c["recall"] >= 0.95 * best]
    near.sort(key=lambda c: (c["bytes"], -c["recall"]))
    return {"chosen": near[0], "ranked_top8": sorted(cands, key=lambda c: (-c["recall"], c["bytes"]))[:8]}


def recall_at(docs, heads, n_tables, n_buckets, k):
    recs = []
    for q in docs:
        gold = {d["nid"] for d in docs if d["label"] == q["label"] and d["nid"] != q["nid"]}
        if not gold:
            continue
        stored, seen = [], set()
        for t in range(n_tables):
            b = q["ks"][t] % n_buckets
            for nid in heads[t][b]:
                if nid == q["nid"] or nid in seen:
                    continue
                seen.add(nid)
                stored.append(nid)
        recs.append(len(gold.intersection(stored[:k])) / len(gold))
    return sum(recs) / len(recs) if recs else 0.0


def main():
    docs = build_label_docs()
    # explicit r16/r64 on a reference profile after build
    profiles_spec = [
        ("P2_4k_h64", 2, 4096, 64),
        ("P2_4k_h256", 2, 4096, 256),
        ("P2_8k_h128", 2, 8192, 128),
        ("P4_4k_h64", 4, 4096, 64),
        ("P8_2k_h16", 8, 2048, 16),
    ]
    profiles = []
    r16 = r64 = None
    for name, nt, nb, hc in profiles_spec:
        p = run_profile(name, nt, nb, hc, docs)
        heads, _ = index_docs(docs, nt, nb, hc)
        p["label_recall_at_16"] = recall_at(docs, heads, nt, nb, 16)
        p["label_recall_at_64"] = recall_at(docs, heads, nt, nb, 64)
        profiles.append(p)
        if name == "P2_8k_h128":
            r16, r64 = p["label_recall_at_16"], p["label_recall_at_64"]

    pick = pareto(profiles)
    fails = []
    if r16 is None or r16 < TH_R16:
        fails.append({"metric": "label_recall@16", "value": r16, "th": TH_R16})
    if r64 is None or r64 < TH_R64:
        fails.append({"metric": "label_recall@64", "value": r64, "th": TH_R64})

    # unrelated: extract keys, see how many entity docs retrieved
    un_hits = []
    heads_ref, _ = index_docs(docs, 2, 8192, 128)
    for s in UNRELATED:
        ks = keys_of(s)
        seen = set()
        for t in range(2):
            b = ks[t] % 8192
            for nid in heads_ref[t][b]:
                seen.add(nid)
        un_hits.append(len(seen))

    out = {
        "gate": "U4A-R3-STRUCTURED-QUERY-ROUTER-00",
        "law": LAW,
        "gold": "independent ENTITY_CANON label, overflow remains in gold",
        "forbidden_relevant_eq_union": False,
        "crc_is_not_route_key": True,
        "n_label_docs": len(docs),
        "thresholds": {"recall@16": TH_R16, "recall@64": TH_R64, "min_coverage": MIN_COVERAGE},
        "ref_profile_r16": r16,
        "ref_profile_r64": r64,
        "unrelated_mean_cands": sum(un_hits) / len(un_hits) if un_hits else 0,
        "profiles": [
            {
                "name": p["name"],
                "n_tables": p["n_tables"],
                "n_buckets": p["n_buckets"],
                "head_cap": p["head_cap"],
                "rejected": p["rejected"],
                "reject_reason": p["reject_reason"],
                "label_index": p["label_index"],
                "label_recall_at_16": p["label_recall_at_16"],
                "label_recall_at_64": p["label_recall_at_64"],
                "by_cap": p["by_cap"],
                "scale": p["scale"],
            }
            for p in profiles
        ],
        "pareto": pick,
        "fails": fails,
        "verdict": "FAIL" if fails else "PASS",
        "first_divergence": fails[0]["metric"] if fails else None,
        "u5": "CLOSED",
    }
    bag = Path(__file__).resolve().parent
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("LABEL_DOCS", len(docs), "R16", r16, "R64", r64)
    for p in profiles:
        print(
            p["name"],
            "rej", p["rejected"],
            "r16", round(p["label_recall_at_16"], 4),
            "r64", round(p["label_recall_at_64"], 4),
            "scale_cov", round(p["scale"]["coverage"], 4),
        )
    print("PARETO", pick.get("chosen"))
    print("UNRELATED_MEAN_CANDS", out["unrelated_mean_cands"])
    if fails:
        print("FIRST_DIVERGENCE", fails[0])
        (bag / "FIRST_DIVERGENCE.md").write_text(json.dumps(fails, indent=2), encoding="utf-8")
        print("U4A_R3_FAIL")
        raise SystemExit(2)
    print("U4A_R3_PASS")


if __name__ == "__main__":
    main()
