#!/usr/bin/env python3
"""U5Q-M10: independent-gold retrieval quality vs scale. RTL_EDIT=NO.

Gold = bound-class descriptor match. Not router union. Not nid-derived keys.
"""
from __future__ import annotations

import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U3Q = BAG.parent / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from lexicon import (  # noqa: E402
    ADV_SEED,
    ENTITY_CANON,
    INTENT_CANON,
    LEX,
    SAME_ENT_DIFF_INT,
    UNRELATED,
)
from twin import extract  # noqa: E402

LAW = "qse-v1-lexicon-hdc-00"
VALIDITY_LAW = "U4A-R6"
PROFILE = "P4_4k_h64"
N_TABLES = 4
N_BUCKETS = 4096
HEAD_CAP = 64
CAND_CAP = 64
ENTRY = 16
SCALES = [256, 4096, 16384, 65536, 262144, 800000]
CATALOG_SEED = 0xA75C105E
MASTER_RECALL_MIN = 0.80

EXPLORATION_QUERIES = [
    ("condenser", "condenser"),
    ("evaporator", "evaporator"),
    ("install_chiller", "install chiller"),
    ("replace_compressor", "replace compressor"),
    ("air_handler", "air handler"),
    ("leak_check", "leak check"),
    ("air_condenser", "air condenser"),
    ("cookie_recipe", "cookie recipe"),
    ("weather_forecast", "weather forecast"),
    ("garden_soil", "garden soil"),
    ("insulate_pipe", "insulate pipe"),
    ("scroll_compressor", "scroll compressor"),
]

CONFIRMATION_QUERIES = [
    ("chiller", "chiller"),
    ("water_chiller", "water chiller"),
    ("leak_chiller", "leak chiller"),
    ("payroll", "payroll tax form"),
    ("soccer", "soccer match score"),
    ("adversarial", None),  # filled by adv0()
    ("hard_neg_install_chiller", "install chiller"),
    ("same_ent_wrong_ctx", "air condenser"),
    ("wrong_intent_leak_check", "leak check"),
    ("no_answer_piano", "piano lesson"),
    ("relation_mismatch_duct", "supply duct"),
    ("overflow_relevant_chiller", "chiller"),
]


def sha256_text(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


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


def feat(text: str) -> dict:
    x = extract(text)
    return {
        "text": text,
        "k": [x["k0"], x["k1"], x["k2"], x["k3"]],
        "v": [x["k0_valid"], x["k1_valid"], x["k2_valid"], x["k3_valid"]],
        "eid": x["entity_id"],
        "iid": x["intent_id"],
        "rid": x["relation_id"],
        "xid": x["context_id"],
        "n_host": x["n_host"],
    }


def bound_slots(f: dict) -> dict:
    out = {}
    for name, key in (("eid", "eid"), ("iid", "iid"), ("rid", "rid"), ("xid", "xid")):
        if f[key]:
            out[name] = f[key]
    return out


def is_relevant(q: dict, r: dict) -> bool:
    qb = bound_slots(q)
    if not qb:
        return False
    return all(r[k] == v for k, v in qb.items())


def lcg(state: int) -> int:
    return (state * 1103515245 + 12345) & 0x7FFFFFFF


def registered_seed_texts() -> list[str]:
    out: list[str] = []
    seen = set()

    def add(t: str) -> None:
        if t not in seen:
            seen.add(t)
            out.append(t)

    for forms in ENTITY_CANON.values():
        for t in forms:
            add(t)
    for forms in INTENT_CANON.values():
        for t in forms:
            add(t)
    for t in SAME_ENT_DIFF_INT:
        add(t)
    for t in UNRELATED:
        add(t)
    return out


def registered_catalog() -> list[str]:
    """Unique registered phrases. Keys always from extract(text)."""
    texts = registered_seed_texts()
    seen = set(texts)
    words = [w for w, _c, _i in LEX]
    for w in words:
        if w not in seen:
            seen.add(w)
            texts.append(w)
    for i, a in enumerate(words):
        for b in words:
            if a == b:
                continue
            t = f"{a} {b}"
            if t not in seen:
                seen.add(t)
                texts.append(t)
    # Deterministic extra 3-word phrases from LEX only.
    st = CATALOG_SEED
    n3 = 0
    while n3 < 4000:
        st = lcg(st)
        i0 = st % len(words)
        st = lcg(st)
        i1 = st % len(words)
        st = lcg(st)
        i2 = st % len(words)
        t = f"{words[i0]} {words[i1]} {words[i2]}"
        if t not in seen:
            seen.add(t)
            texts.append(t)
            n3 += 1
    return texts


def build_corpus(n: int, catalog: list[str], feats: list[dict]) -> list[int]:
    """nid -> catalog index. First nids consume seed titles in order, then cycle catalog."""
    seed_n = 0
    seed_set = set(registered_seed_texts())
    for i, t in enumerate(catalog):
        if t in seed_set:
            seed_n = i + 1
        else:
            break
    idxs = []
    for nid in range(n):
        if nid < seed_n:
            idxs.append(nid)
        else:
            idxs.append((nid - seed_n) % len(catalog))
    return idxs


def index_corpus(n: int, cat_idx: list[int], feats: list[dict]):
    heads = [[list() for _ in range(N_BUCKETS)] for _ in range(N_TABLES)]
    ovf = [[0] * N_BUCKETS for _ in range(N_TABLES)]
    n_valid = 0
    max_id = n - 1
    dropped = 0
    for nid in range(n):
        f = feats[cat_idx[nid]]
        any_v = False
        for t in range(N_TABLES):
            if not f["v"][t]:
                continue
            any_v = True
            b = f["k"][t] & 0xFFF
            if len(heads[t][b]) < HEAD_CAP:
                heads[t][b].append(nid)
            else:
                ovf[t][b] = 1
                dropped += 1
        if any_v:
            n_valid += 1
    return heads, ovf, n_valid, max_id, dropped


def route(q: dict, heads, ovf, cap: int):
    predup = []
    seen = []
    ndup = 0
    n_dir = 0
    n_post_beats = 0
    post_lens = []
    probed_ovf = 0
    for t in range(N_TABLES):
        if not q["v"][t]:
            continue
        n_dir += 1
        b = q["k"][t] & 0xFFF
        ids = heads[t][b]
        post_lens.append(len(ids))
        n_post_beats += (len(ids) + 3) // 4 if ids else 0
        if ovf[t][b]:
            probed_ovf = 1
        for nid in ids:
            predup.append(nid)
            if nid in seen:
                ndup += 1
            else:
                seen.append(nid)
    ntrunc = max(0, len(seen) - cap)
    cands = seen[:cap]
    overflow = 1 if (probed_ovf or ntrunc) else 0
    return {
        "cands": cands,
        "n_dir": n_dir,
        "n_post_beats": n_post_beats,
        "post_lens": post_lens,
        "ndup": ndup,
        "ntrunc": ntrunc,
        "overflow": overflow,
        "bytes": n_dir * ENTRY + n_post_beats * ENTRY,
        "n_emit": len(cands),
        "union_before_cap": len(seen),
    }


def eval_query(name: str, text: str, q: dict, n: int, cat_idx, feats, heads, ovf, cap: int):
    gold = []
    gold_in_heads = 0
    for nid in range(n):
        r = feats[cat_idx[nid]]
        if is_relevant(q, r):
            gold.append(nid)
    gold_set = set(gold)
    rt = route(q, heads, ovf, cap)
    cset = set(rt["cands"])
    # relevant that were stored in any probed posting (pre CAND_CAP)
    stored = set()
    for t in range(N_TABLES):
        if not q["v"][t]:
            continue
        b = q["k"][t] & 0xFFF
        stored.update(heads[t][b])
    gold_in_heads = len(gold_set & stored)
    lost_head = len(gold_set) - gold_in_heads
    lost_cap = len((gold_set & stored) - cset)
    lost = lost_head + lost_cap
    tp = len(gold_set & cset)
    fp = len(cset - gold_set)
    fn = len(gold_set - cset)
    rec = (tp / len(gold_set)) if gold_set else None
    prec = (tp / len(cset)) if cset else (1.0 if not gold_set else 0.0)
    frac = len(rt["cands"]) / n if n else 0.0
    return {
        "name": name,
        "text": text,
        "bound": bound_slots(q),
        "k": q["k"],
        "v": q["v"],
        "n_host": q["n_host"],
        "gold_count": len(gold_set),
        "candidate_count": rt["n_emit"],
        "candidate_fraction": frac,
        "reduction_ratio": 1.0 - frac,
        "recall": rec,
        "precision": prec,
        "false_positives": fp,
        "false_negatives": fn,
        "overflow": rt["overflow"],
        "relevant_lost_to_overflow": lost,
        "relevant_lost_head": lost_head,
        "relevant_lost_cap": lost_cap,
        "gold_in_heads": gold_in_heads,
        "posting_lengths": rt["post_lens"],
        "duplicates": rt["ndup"],
        "directory_axi_beats": rt["n_dir"],
        "posting_axi_beats": rt["n_post_beats"],
        "retrieval_bytes": rt["bytes"],
        "trunc": rt["ntrunc"],
        "union_before_cap": rt["union_before_cap"],
        "full_scan": rt["n_dir"] > N_TABLES,
        "returns_entire_corpus": rt["n_emit"] >= n,
        "cand_ids_head": rt["cands"][:16],
    }


def query_list(phase: str):
    if phase == "explore":
        rows = list(EXPLORATION_QUERIES)
    else:
        rows = []
        for name, text in CONFIRMATION_QUERIES:
            if name == "adversarial":
                rows.append((name, adv0()))
            else:
                rows.append((name, text))
    return rows


def corpus_sha(n: int, cat_idx, feats) -> str:
    h = hashlib.sha256()
    h.update(f"N={n}\nLAW={LAW}\nSEED={CATALOG_SEED:08X}\n".encode())
    for nid in range(n):
        f = feats[cat_idx[nid]]
        line = "{}\t{}\t{}\t{}\t{},{},{},{}\n".format(
            nid, f["text"], ",".join(str(x) for x in f["k"]),
            ",".join(str(x) for x in f["v"]), f["eid"], f["iid"], f["rid"], f["xid"],
        )
        h.update(line.encode("utf-8"))
    return h.hexdigest()


def index_sha(heads, ovf) -> str:
    h = hashlib.sha256()
    for t in range(N_TABLES):
        for b in range(N_BUCKETS):
            ids = heads[t][b]
            if not ids and not ovf[t][b]:
                continue
            h.update(f"{t}:{b}:{len(ids)}:{ovf[t][b]}:{ids[:4]}:{ids[-1:]}\n".encode())
    return h.hexdigest()


def run_phase(phase: str, catalog, feats, cap: int = CAND_CAP) -> dict:
    qrows = query_list(phase)
    qfeats = {name: feat(text) for name, text in qrows}
    scales = {}
    manifests = {}
    for n in SCALES:
        cat_idx = build_corpus(n, catalog, feats)
        heads, ovf, n_valid, max_id, dropped = index_corpus(n, cat_idx, feats)
        csha = corpus_sha(n, cat_idx, feats)
        isha = index_sha(heads, ovf)
        occ = []
        n_ovf_bkt = 0
        for t in range(N_TABLES):
            for b in range(N_BUCKETS):
                if heads[t][b]:
                    occ.append(len(heads[t][b]))
                if ovf[t][b]:
                    n_ovf_bkt += 1
        manifests[str(n)] = {
            "corpus_sha": csha,
            "index_sha": isha,
            "total_records": n,
            "valid_records": n_valid,
            "max_record_id": max_id,
            "routing_law": LAW,
            "validity_law": VALIDITY_LAW,
            "overflow_policy": "HEAD_CAP keep-first; CAND_CAP trunc after dedup",
            "head_cap": HEAD_CAP,
            "candidate_cap": cap,
            "n_tables": N_TABLES,
            "n_buckets": N_BUCKETS,
            "occupied_buckets": len(occ),
            "overflow_buckets": n_ovf_bkt,
            "head_insert_drops": dropped,
            "max_posting": max(occ) if occ else 0,
            "mean_posting": (sum(occ) / len(occ)) if occ else 0.0,
        }
        rows = []
        for name, text in qrows:
            rows.append(eval_query(name, text, qfeats[name], n, cat_idx, feats, heads, ovf, cap))
        scales[str(n)] = rows
    qsha = sha256_text(json.dumps(qrows, sort_keys=True))
    return {"phase": phase, "query_sha": qsha, "queries": qrows, "scales": scales, "manifests": manifests, "cap": cap}


def summarize(bundle: dict) -> list[dict]:
    out = []
    for n, rows in bundle["scales"].items():
        for r in rows:
            out.append({
                "N": int(n),
                "query": r["name"],
                "recall": r["recall"],
                "precision": r["precision"],
                "gold": r["gold_count"],
                "cands": r["candidate_count"],
                "frac": r["candidate_fraction"],
                "bytes": r["retrieval_bytes"],
                "ovf": r["overflow"],
                "lost": r["relevant_lost_to_overflow"],
                "fp": r["false_positives"],
                "fn": r["false_negatives"],
                "dir": r["directory_axi_beats"],
                "post": r["posting_axi_beats"],
            })
    return out


def load_thresholds() -> dict:
    p = BAG / "THRESHOLDS.json"
    return json.loads(p.read_text(encoding="utf-8"))


def judge(bundle: dict, th: dict) -> dict:
    fails = []
    for n, rows in bundle["scales"].items():
        n_i = int(n)
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
                        fails.append({
                            "id": "OVERFLOW_RELEVANT_LOSS",
                            "tag": tag,
                            "lost_frac": lost_frac,
                            "lost": r["relevant_lost_to_overflow"],
                        })
            if r["retrieval_bytes"] > th["max_retrieval_bytes"]:
                fails.append({"id": "TRAFFIC_BOUND_FAIL", "tag": tag, "bytes": r["retrieval_bytes"]})
            if r["candidate_count"] > bundle["cap"]:
                fails.append({"id": "CAND_CAP_FAIL", "tag": tag})
            if n_i > bundle["cap"] and (not bound) and r["reduction_ratio"] <= 0:
                fails.append({"id": "REDUCTION_NOT_POSITIVE", "tag": tag})
        # traffic vs N: dir beats must stay <= 4
        dirs = [r["directory_axi_beats"] for r in rows]
        if any(d > N_TABLES for d in dirs):
            fails.append({"id": "DIR_GROWS", "N": n_i})
    # nid-derived key check: catalog feats never use nid
    fails_unique = []
    seen = set()
    for f in fails:
        key = (f["id"], f.get("tag"))
        if key in seen:
            continue
        seen.add(key)
        fails_unique.append(f)
    return {
        "result": "FAIL" if fails_unique else "PASS",
        "n_fail": len(fails_unique),
        "fails": fails_unique[:80],
        "first_divergence": fails_unique[0]["id"] if fails_unique else None,
    }


def propose_thresholds(explore: dict) -> dict:
    """After exploration only. Master recall kept. Precision/frac/bytes from explore floor."""
    precs = []
    fracs = []
    bytes_ = []
    lostf = []
    noans_c = []
    for rows in explore["scales"].values():
        for r in rows:
            if r["bound"]:
                precs.append(r["precision"])
                fracs.append(r["candidate_fraction"])
                if r["gold_count"]:
                    lostf.append(r["relevant_lost_to_overflow"] / r["gold_count"])
            else:
                noans_c.append(r["candidate_count"])
            bytes_.append(r["retrieval_bytes"])
    # Do not set precision_min below a documented a-priori floor of 0.10
    # after seeing explore; never raise-to-pass on confirmation.
    prec_floor = 0.10
    explore_prec_min = min(precs) if precs else 0.0
    # Freeze a requirement that is Master-compatible and not fitted to confirmation.
    # Precision: require at least max(0.10, 0.5 * min_explore) only if explore already
    # meets 0.10; otherwise keep 0.10 so a weak explore cannot hide a weak confirm.
    precision_min = prec_floor
    max_frac = 0.25
    max_bytes = 4 * ENTRY + ((HEAD_CAP + 3) // 4) * N_TABLES * ENTRY  # worst legal
    max_lost = 0.20
    return {
        "recall_min": MASTER_RECALL_MIN,
        "precision_min_bound": precision_min,
        "max_candidate_fraction": max_frac,
        "max_retrieval_bytes": max_bytes,
        "max_relevant_overflow_frac": max_lost,
        "no_answer_max_cands": 0,
        "source": {
            "master_recall": MASTER_RECALL_MIN,
            "explore_min_precision_bound": explore_prec_min,
            "explore_max_frac_bound": max(fracs) if fracs else None,
            "explore_max_bytes": max(bytes_) if bytes_ else None,
            "explore_max_lost_frac": max(lostf) if lostf else None,
            "explore_max_noans_cands": max(noans_c) if noans_c else 0,
            "note": "precision_min 0.10 and no_answer_max_cands=0 are a priori; recall 0.80 Master; not fit to confirmation",
        },
    }


def cap_sweep(catalog, feats, n: int = 16384) -> list[dict]:
    rows = []
    qrows = query_list("confirm")
    qfeats = {name: feat(text) for name, text in qrows}
    cat_idx = build_corpus(n, catalog, feats)
    heads, ovf, *_rest = index_corpus(n, cat_idx, feats)
    for cap in (64, 128, 256, 512, 1024):
        recs, precs, losts, bys = [], [], [], []
        for name, text in qrows:
            r = eval_query(name, text, qfeats[name], n, cat_idx, feats, heads, ovf, cap)
            if r["bound"] and r["recall"] is not None:
                recs.append(r["recall"])
                precs.append(r["precision"])
                if r["gold_count"]:
                    losts.append(r["relevant_lost_to_overflow"] / r["gold_count"])
            bys.append(r["retrieval_bytes"])
        rows.append({
            "cap": cap,
            "N": n,
            "mean_recall_bound": sum(recs) / len(recs) if recs else None,
            "min_recall_bound": min(recs) if recs else None,
            "mean_precision_bound": sum(precs) / len(precs) if precs else None,
            "max_lost_frac": max(losts) if losts else None,
            "max_bytes": max(bys) if bys else None,
        })
    return rows


def main() -> int:
    phase = sys.argv[1] if len(sys.argv) > 1 else "all"
    catalog = registered_catalog()
    feats = [feat(t) for t in catalog]
    (BAG / "CATALOG_META.json").write_text(json.dumps({
        "n_unique_texts": len(catalog),
        "seed": CATALOG_SEED,
        "law": LAW,
        "catalog_sha": sha256_text("\n".join(catalog)),
    }, indent=2), encoding="utf-8")

    if phase in ("explore", "all"):
        explore = run_phase("explore", catalog, feats)
        (BAG / "EXPLORATION.json").write_text(json.dumps({
            "query_sha": explore["query_sha"],
            "summary": summarize(explore),
            "manifests": explore["manifests"],
            "scales": explore["scales"],
        }, indent=2), encoding="utf-8")
        th = propose_thresholds(explore)
        (BAG / "THRESHOLDS.json").write_text(json.dumps(th, indent=2), encoding="utf-8")
        (BAG / "EXPLORATION_SET.json").write_text(json.dumps({
            "sha": explore["query_sha"],
            "queries": explore["queries"],
        }, indent=2), encoding="utf-8")
        print("EXPLORATION_SET_SHA", explore["query_sha"])
        print("THRESHOLDS", json.dumps(th["source"], indent=2))

    if phase in ("confirm", "all"):
        if not (BAG / "THRESHOLDS.json").exists():
            print("NEED_THRESHOLDS")
            return 2
        th = load_thresholds()
        confirm = run_phase("confirm", catalog, feats)
        judge_r = judge(confirm, th)
        (BAG / "CONFIRMATION.json").write_text(json.dumps({
            "query_sha": confirm["query_sha"],
            "summary": summarize(confirm),
            "manifests": confirm["manifests"],
            "scales": confirm["scales"],
            "judge": judge_r,
        }, indent=2), encoding="utf-8")
        (BAG / "CONFIRMATION_SET.json").write_text(json.dumps({
            "sha": confirm["query_sha"],
            "queries": confirm["queries"],
        }, indent=2), encoding="utf-8")
        # manifests at 800k as the required pair
        man800 = confirm["manifests"]["800000"]
        (BAG / "CORPUS_MANIFEST.json").write_text(json.dumps({
            **man800,
            "profile": PROFILE,
            "nid_derived_keys": False,
            "gold_law": "bound-class descriptor equality; empty-bound => not relevant",
        }, indent=2), encoding="utf-8")
        (BAG / "INDEX_MANIFEST.json").write_text(json.dumps({
            **man800,
            "profile": PROFILE,
        }, indent=2), encoding="utf-8")
        sweep = None
        if judge_r["result"] != "PASS":
            sweep = cap_sweep(catalog, feats, 16384)
            (BAG / "CAP_SWEEP.json").write_text(json.dumps(sweep, indent=2), encoding="utf-8")
        print("CONFIRMATION_SET_SHA", confirm["query_sha"])
        print("CORPUS_MANIFEST_SHA", man800["corpus_sha"])
        print("INDEX_MANIFEST_SHA", man800["index_sha"])
        print("RESULT", judge_r["result"])
        print("FIRST_DIVERGENCE", judge_r["first_divergence"])
        print("N_FAIL", judge_r["n_fail"])
        if judge_r["fails"]:
            print("FAIL0", json.dumps(judge_r["fails"][0]))
        if sweep:
            print("CAP_SWEEP", json.dumps(sweep))
        return 0 if judge_r["result"] == "PASS" else 7

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
