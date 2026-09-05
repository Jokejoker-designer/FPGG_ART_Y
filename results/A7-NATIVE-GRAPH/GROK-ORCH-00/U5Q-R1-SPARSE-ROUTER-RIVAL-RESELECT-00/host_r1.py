#!/usr/bin/env python3
"""U5Q-R1: rival profiles on frozen qse keys + U5Q gold/thresholds. No XOR, no nid keys."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402

ENTRY = u5q.ENTRY
SCALES = u5q.SCALES

PROFILES = [
    {"name": "P4_4k_h64_c64", "tables": [0, 1, 2, 3], "nb": 4096, "head": 64, "cap": 64, "combine": "union", "control": True},
    {"name": "P2_T02_4k_h64_c64", "tables": [0, 2], "nb": 4096, "head": 64, "cap": 64, "combine": "union", "control": False},
    {"name": "P2_T01_4k_h64_c64", "tables": [0, 1], "nb": 4096, "head": 64, "cap": 64, "combine": "union", "control": False},
    {"name": "P2_T02_8k_h128_c192", "tables": [0, 2], "nb": 8192, "head": 128, "cap": 192, "combine": "union", "control": False},
    {"name": "P4_4k_h128_c128", "tables": [0, 1, 2, 3], "nb": 4096, "head": 128, "cap": 128, "combine": "union", "control": False},
    {"name": "P4_4k_h256_c256", "tables": [0, 1, 2, 3], "nb": 4096, "head": 256, "cap": 256, "combine": "union", "control": False},
    {"name": "P4_8k_h64_c64", "tables": [0, 1, 2, 3], "nb": 8192, "head": 64, "cap": 64, "combine": "union", "control": False},
    {"name": "P4_4k_h64_c64_AND", "tables": [0, 1, 2, 3], "nb": 4096, "head": 64, "cap": 64, "combine": "and", "control": False},
    {"name": "P2_T02_4k_h64_c64_AND", "tables": [0, 2], "nb": 4096, "head": 64, "cap": 64, "combine": "and", "control": False},
]


def bmask(nb: int) -> int:
    return nb - 1


def index_corpus(n, cat_idx, feats, tables, nb, head):
    heads = [[list() for _ in range(nb)] for _ in range(4)]
    ovf = [[0] * nb for _ in range(4)]
    mask = bmask(nb)
    for nid in range(n):
        f = feats[cat_idx[nid]]
        for t in tables:
            if not f["v"][t]:
                continue
            b = f["k"][t] & mask
            if len(heads[t][b]) < head:
                heads[t][b].append(nid)
            else:
                ovf[t][b] = 1
    return heads, ovf


def route(q, heads, ovf, tables, nb, cap, combine):
    mask = bmask(nb)
    n_dir = 0
    n_post = 0
    post_lens = []
    probed_ovf = 0
    lists = []
    probed = []
    for t in tables:
        if not q["v"][t]:
            continue
        n_dir += 1
        b = q["k"][t] & mask
        ids = heads[t][b]
        probed.append(t)
        lists.append(ids)
        post_lens.append(len(ids))
        n_post += (len(ids) + 3) // 4 if ids else 0
        if ovf[t][b]:
            probed_ovf = 1
    if not lists:
        ordered = []
        ndup = 0
    elif combine == "and":
        common = set(lists[0])
        for lst in lists[1:]:
            common &= set(lst)
        ordered = [x for x in lists[0] if x in common]
        ndup = sum(len(lst) for lst in lists) - len(common)
    else:
        seen = set()
        ordered = []
        ndup = 0
        for lst in lists:
            for nid in lst:
                if nid in seen:
                    ndup += 1
                else:
                    seen.add(nid)
                    ordered.append(nid)
    ntrunc = max(0, len(ordered) - cap)
    cands = ordered[:cap]
    return {
        "cands": cands,
        "n_dir": n_dir,
        "n_post_beats": n_post,
        "post_lens": post_lens,
        "ndup": ndup,
        "ntrunc": ntrunc,
        "overflow": 1 if (probed_ovf or ntrunc) else 0,
        "bytes": n_dir * ENTRY + n_post * ENTRY,
        "n_emit": len(cands),
        "union_before_cap": len(ordered),
        "probed": probed,
    }


def eval_one(name, text, q, n, cat_idx, feats, heads, ovf, prof, rel_cats):
    gold_count = 0
    for nid in range(n):
        if cat_idx[nid] in rel_cats:
            gold_count += 1
    rt = route(q, heads, ovf, prof["tables"], prof["nb"], prof["cap"], prof["combine"])
    stored = set()
    mask = bmask(prof["nb"])
    for t in rt["probed"]:
        b = q["k"][t] & mask
        stored.update(heads[t][b])
    if prof["combine"] == "and" and rt["probed"]:
        inter = None
        for t in rt["probed"]:
            b = q["k"][t] & mask
            s = set(heads[t][b])
            inter = s if inter is None else (inter & s)
        stored = inter or set()
    gold_in_heads = sum(1 for nid in stored if cat_idx[nid] in rel_cats)
    cset = set(rt["cands"])
    tp = sum(1 for nid in cset if cat_idx[nid] in rel_cats)
    fp = len(cset) - tp
    lost_head = gold_count - gold_in_heads
    lost_cap = sum(1 for nid in stored if cat_idx[nid] in rel_cats and nid not in cset)
    lost = lost_head + lost_cap
    rec = (tp / gold_count) if gold_count else None
    prec = (tp / len(cset)) if cset else (1.0 if gold_count == 0 else 0.0)
    frac = len(rt["cands"]) / n if n else 0.0
    return {
        "name": name,
        "text": text,
        "bound": u5q.bound_slots(q),
        "n_host": q["n_host"],
        "gold_count": gold_count,
        "candidate_count": rt["n_emit"],
        "candidate_fraction": frac,
        "reduction_ratio": 1.0 - frac,
        "recall": rec,
        "precision": prec,
        "false_positives": fp,
        "false_negatives": gold_count - tp,
        "overflow": rt["overflow"],
        "relevant_lost_to_overflow": lost,
        "directory_axi_beats": rt["n_dir"],
        "posting_axi_beats": rt["n_post_beats"],
        "retrieval_bytes": rt["bytes"],
        "full_scan": False,
        "returns_entire_corpus": rt["n_emit"] >= n,
    }


def judge_rows(rows, n, cap, th):
    fails = []
    for r in rows:
        tag = f"{r['name']}@N={n}"
        if r["n_host"]:
            fails.append({"id": "HOST_SEMANTIC_LEAK", "tag": tag})
        if r["full_scan"]:
            fails.append({"id": "FULL_SCAN", "tag": tag})
        bound = r["bound"]
        if not bound:
            if r["candidate_count"] > th["no_answer_max_cands"]:
                fails.append({"id": "NO_ANSWER_FP", "tag": tag, "cands": r["candidate_count"]})
            if r["returns_entire_corpus"]:
                fails.append({"id": "UNRELATED_FULL_CORPUS", "tag": tag})
            if n > cap and r["reduction_ratio"] <= 0:
                fails.append({"id": "REDUCTION_NOT_POSITIVE", "tag": tag})
        else:
            rec = r["recall"]
            if rec is None or rec < th["recall_min"]:
                fails.append({"id": "RECALL_FAIL", "tag": tag, "recall": rec, "gold": r["gold_count"]})
            if r["precision"] < th["precision_min_bound"]:
                fails.append({"id": "PRECISION_FAIL", "tag": tag, "precision": r["precision"]})
            if r["candidate_fraction"] > th["max_candidate_fraction"]:
                fails.append({"id": "CAND_FRACTION_FAIL", "tag": tag, "frac": r["candidate_fraction"]})
            if r["gold_count"] > 0:
                lost_frac = r["relevant_lost_to_overflow"] / r["gold_count"]
                if lost_frac > th["max_relevant_overflow_frac"]:
                    fails.append({"id": "OVERFLOW_RELEVANT_LOSS", "tag": tag, "lost_frac": lost_frac})
        if r["retrieval_bytes"] > th["max_retrieval_bytes"]:
            fails.append({"id": "TRAFFIC_BOUND_FAIL", "tag": tag, "bytes": r["retrieval_bytes"]})
        if r["candidate_count"] > cap:
            fails.append({"id": "CAND_CAP_FAIL", "tag": tag})
    return fails


def main() -> int:
    th = json.loads((BAG_U5Q / "THRESHOLDS.json").read_text(encoding="utf-8"))
    catalog = u5q.registered_catalog()
    feats = [u5q.feat(t) for t in catalog]
    qrows = u5q.query_list("confirm")
    qfeats = {name: u5q.feat(text) for name, text in qrows}
    rel = {
        name: {i for i, f in enumerate(feats) if u5q.is_relevant(qfeats[name], f)}
        for name, _text in qrows
    }

    report = []
    for prof in PROFILES:
        print("PROFILE", prof["name"], flush=True)
        scale_rows = {}
        all_fails = []
        bytes_16384 = []
        cands_16384 = []
        for n in SCALES:
            cat_idx = u5q.build_corpus(n, catalog, feats)
            heads, ovf = index_corpus(n, cat_idx, feats, prof["tables"], prof["nb"], prof["head"])
            rows = []
            for name, text in qrows:
                rows.append(eval_one(
                    name, text, qfeats[name], n, cat_idx, feats, heads, ovf, prof, rel[name],
                ))
            fails = judge_rows(rows, n, prof["cap"], th)
            all_fails.extend(fails)
            scale_rows[str(n)] = {
                "summary": [
                    {
                        "query": r["name"],
                        "recall": r["recall"],
                        "precision": r["precision"],
                        "gold": r["gold_count"],
                        "cands": r["candidate_count"],
                        "lost": r["relevant_lost_to_overflow"],
                        "bytes": r["retrieval_bytes"],
                        "fp": r["false_positives"],
                        "ovf": r["overflow"],
                    }
                    for r in rows
                ],
                "n_fail": len(fails),
            }
            if n == 16384:
                bytes_16384 = [r["retrieval_bytes"] for r in rows]
                cands_16384 = [r["candidate_count"] for r in rows]
        meets = len(all_fails) == 0
        rec = {
            "name": prof["name"],
            "control": prof["control"],
            "tables": prof["tables"],
            "nb": prof["nb"],
            "head": prof["head"],
            "cap": prof["cap"],
            "combine": prof["combine"],
            "meets_u5q_bar": meets,
            "n_fail": len(all_fails),
            "first_fail": all_fails[0] if all_fails else None,
            "fail_ids": {},
            "mean_bytes_16384": (sum(bytes_16384) / len(bytes_16384)) if bytes_16384 else None,
            "mean_cands_16384": (sum(cands_16384) / len(cands_16384)) if cands_16384 else None,
            "scales": scale_rows,
        }
        for f in all_fails:
            rec["fail_ids"][f["id"]] = rec["fail_ids"].get(f["id"], 0) + 1
        report.append(rec)
        print("  meets", meets, "n_fail", rec["n_fail"], "first", rec["first_fail"], flush=True)

    passers = [p for p in report if p["meets_u5q_bar"] and not p["control"]]
    passers.sort(key=lambda p: (p["mean_bytes_16384"], p["mean_cands_16384"]))
    chosen = passers[0]["name"] if passers else None
    result = "PASS" if passers else "FAIL"
    first = None if passers else "NO_RIVAL_MEETS_U5Q_BAR"
    out = {
        "result": result,
        "first_divergence": first,
        "chosen": chosen,
        "n_passers": len(passers),
        "thresholds": th,
        "profiles": report,
    }
    (BAG / "RIVAL.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("RESULT", result)
    print("CHOSEN", chosen)
    print("FIRST_DIVERGENCE", first)
    print("PASSERS", [p["name"] for p in passers])
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
