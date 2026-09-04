#!/usr/bin/env python3
"""U4A-R2 sparse router rival. Independent gold BEFORE router output.

No relevant=set(union). Overflowed records stay in gold.
CAND_CAP from Pareto, not hard-coded 256.
PROGRAM=NO. HOST_MODEL only.
"""
from __future__ import annotations

import json
import zlib
from pathlib import Path

N = 800_000
N_QUERY = 200
SEED = 0xA7FE02
POSTING_B = 16
DIR_ENTRY_B = 16
MIN_COVERAGE = 0.20
MIN_HEAD_HIT = 0.15
CAPS = [64, 128, 192, 256, 384, 512, 1024, 2048]


def crc16_ccitt_false(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) & 0xFFFF) ^ 0x1021
            else:
                crc = (crc << 1) & 0xFFFF
    return crc


def qfe_keys(tokens: list[int]) -> tuple[int, int, int, int]:
    xor = 0
    sm = 0
    for b in tokens:
        xor ^= b
        sm = (sm + b) & 0xFFFF
    crc = crc16_ccitt_false(bytes(tokens))
    first, last, L = tokens[0], tokens[-1], len(tokens)
    k0 = crc
    k1 = crc ^ ((xor << 8) | first)
    k2 = ((sm & 0xFF) << 8 | xor) ^ ((last << 8) | first)
    k3 = ((L << 8) | xor) ^ crc
    return k0 & 0xFFFF, k1 & 0xFFFF, k2 & 0xFFFF, k3 & 0xFFFF


def rec_keys(nid: int) -> tuple[int, ...]:
    raw = nid.to_bytes(4, "little")
    h = zlib.crc32(raw) & 0xFFFFFFFF
    k = []
    x = h
    for i in range(8):
        x = (x * 0x45D9F3B + nid + i) & 0xFFFFFFFF
        k.append((x ^ (h >> (i * 3))) & 0xFFFF)
    return tuple(k)


def qk8_from_qfe(qk: tuple[int, int, int, int]) -> list[int]:
    return list(qk) + [
        (qk[0] ^ qk[1]) & 0xFFFF,
        (qk[2] ^ qk[3]) & 0xFFFF,
        (qk[0] + qk[2]) & 0xFFFF,
        (qk[1] + qk[3]) & 0xFFFF,
    ]


def build_index(n_tables: int, n_buckets: int, head_cap: int):
    """Store heads AND inverted membership for gold (all nids, including overflow)."""
    heads = [[list() for _ in range(n_buckets)] for _ in range(n_tables)]
    # gold_lists[t][b] = every nid whose rec_keys[t] hashes to b (pre-head_cap)
    gold_lists = [[list() for _ in range(n_buckets)] for _ in range(n_tables)]
    overflow = 0
    covered = set()
    occ = []
    for nid in range(N):
        ks = rec_keys(nid)
        for t in range(n_tables):
            b = ks[t] % n_buckets
            gold_lists[t][b].append(nid)
            bucket = heads[t][b]
            if len(bucket) < head_cap:
                bucket.append(nid)
                covered.add(nid)
            else:
                overflow += 1
    for t in range(n_tables):
        for bkt in heads[t]:
            occ.append(len(bkt))
    occ.sort()
    return heads, gold_lists, {
        "overflow_posts": overflow,
        "coverage": len(covered) / N,
        "occ_p50": occ[len(occ) // 2],
        "occ_p99": occ[int(len(occ) * 0.99)],
        "occ_max": occ[-1],
        "empty_frac": sum(1 for x in occ if x == 0) / len(occ),
        "dir_bytes": n_tables * n_buckets * DIR_ENTRY_B,
        "slot_bytes": n_tables * n_buckets * head_cap * 4,
    }


def run_profile(name: str, n_tables: int, n_buckets: int, head_cap: int):
    heads, gold_lists, st = build_index(n_tables, n_buckets, head_cap)
    rejected = st["coverage"] < MIN_COVERAGE
    rng = SEED
    rows = []
    for qi in range(N_QUERY):
        rng = (1103515245 * rng + 12345) & 0x7FFFFFFF
        toks = [((rng >> 8) + qi + j) & 0xFF or 1 for j in range(3)]
        qk = qfe_keys(toks)
        qk8 = qk8_from_qfe(qk)
        # GOLD independent of admission / head_cap
        gold = set()
        for t in range(n_tables):
            b = qk8[t] % n_buckets
            gold.update(gold_lists[t][b])
        stored = []
        seen = set()
        dups = 0
        overflow_in_gold = 0
        for t in range(n_tables):
            b = qk8[t] % n_buckets
            for nid in gold_lists[t][b]:
                if nid not in heads[t][b]:
                    overflow_in_gold += 1
            for nid in heads[t][b]:
                if nid in seen:
                    dups += 1
                else:
                    seen.add(nid)
                    stored.append(nid)
        head_hit = (len(gold.intersection(seen)) / len(gold)) if gold else 0.0
        for cap in CAPS:
            cands = stored[:cap]
            rec = (len(gold.intersection(cands)) / len(gold)) if gold else 0.0
            bytes_q = len(cands) * POSTING_B + n_tables * DIR_ENTRY_B
            rows.append({
                "q": qi,
                "cap": cap,
                "gold": len(gold),
                "stored": len(stored),
                "cands": len(cands),
                "dups": dups,
                "overflow_in_gold": overflow_in_gold,
                "head_hit": head_hit,
                "recall": rec,
                "bytes_q": bytes_q,
            })
    by_cap = {}
    for cap in CAPS:
        sl = [r for r in rows if r["cap"] == cap]
        by_cap[str(cap)] = {
            "mean_gold": sum(r["gold"] for r in sl) / len(sl),
            "mean_stored": sum(r["stored"] for r in sl) / len(sl),
            "mean_cands": sum(r["cands"] for r in sl) / len(sl),
            "mean_bytes": sum(r["bytes_q"] for r in sl) / len(sl),
            "mean_dups": sum(r["dups"] for r in sl) / len(sl),
            "mean_overflow_in_gold": sum(r["overflow_in_gold"] for r in sl) / len(sl),
            "mean_head_hit": sum(r["head_hit"] for r in sl) / len(sl),
            "mean_recall": sum(r["recall"] for r in sl) / len(sl),
        }
    mean_head_hit = by_cap[str(CAPS[0])]["mean_head_hit"]
    if mean_head_hit < MIN_HEAD_HIT:
        rejected = True
    return {
        "name": name,
        "n_tables": n_tables,
        "n_buckets": n_buckets,
        "head_cap": head_cap,
        "index": st,
        "rejected": rejected,
        "reject_reason": (
            "coverage" if st["coverage"] < MIN_COVERAGE
            else ("head_hit" if mean_head_hit < MIN_HEAD_HIT else None)
        ),
        "by_cap": by_cap,
    }


def pareto_pick(profiles: list[dict]) -> dict:
    """Among non-rejected (profile, cap), max recall, then min bytes, then min overflow."""
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
                "overflow_posts": p["index"]["overflow_posts"],
                "coverage": p["index"]["coverage"],
                "head_hit": b["mean_head_hit"],
            })
    if not cands:
        return {"chosen": None, "reason": "all_profiles_rejected"}
    # Pareto-ish knee: among points with recall >= 0.95*max_recall, take min bytes
    best_r = max(c["recall"] for c in cands)
    near = [c for c in cands if c["recall"] >= 0.95 * best_r]
    near.sort(key=lambda c: (c["bytes"], c["overflow_posts"], -c["recall"]))
    chosen = near[0]
    # full ranking for audit
    ranked = sorted(cands, key=lambda c: (-c["recall"], c["bytes"], c["overflow_posts"]))
    return {"chosen": chosen, "ranked_top10": ranked[:10], "n_feasible": len(cands)}


def main():
    profiles = [
        run_profile("P2_4k_h64", 2, 4096, 64),
        run_profile("P2_4k_h256", 2, 4096, 256),
        run_profile("P4_4k_h64", 4, 4096, 64),
        run_profile("P2_8k_h128", 2, 8192, 128),
        run_profile("P8_2k_h16", 8, 2048, 16),
    ]
    pick = pareto_pick(profiles)
    out = {
        "gate": "U4A-R2-SPARSE-ROUTER-RIVAL-00",
        "evidence_class": "HOST_MODEL",
        "n": N,
        "n_query": N_QUERY,
        "law": "qfe-v1-crc16-mix-00",
        "gold": "independent rec_keys bucket membership INCLUDING overflow",
        "forbidden_relevant_eq_union": False,
        "min_coverage": MIN_COVERAGE,
        "min_head_hit": MIN_HEAD_HIT,
        "caps_swept": CAPS,
        "profiles": [
            {
                "name": p["name"],
                "n_tables": p["n_tables"],
                "n_buckets": p["n_buckets"],
                "head_cap": p["head_cap"],
                "rejected": p["rejected"],
                "reject_reason": p["reject_reason"],
                "index": p["index"],
                "by_cap": p["by_cap"],
            }
            for p in profiles
        ],
        "pareto": pick,
        "note": "HOST_MODEL. Not a silicon freeze. CAND_CAP is Pareto-chosen, not 256 hardcoded.",
    }
    bag = Path(__file__).resolve().parent
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("MIN_COVERAGE", MIN_COVERAGE, "MIN_HEAD_HIT", MIN_HEAD_HIT)
    for p in profiles:
        print(
            p["name"],
            "rej", p["rejected"], p["reject_reason"],
            "cov", round(p["index"]["coverage"], 4),
            "ovf", p["index"]["overflow_posts"],
            "r256", round(p["by_cap"]["256"]["mean_recall"], 4),
            "hit", round(p["by_cap"]["256"]["mean_head_hit"], 4),
        )
    print("PARETO", pick.get("chosen"))
    if pick.get("chosen") is None:
        print("U4A_R2_ALL_REJECTED")
        raise SystemExit(3)
    print("U4A_R2_RIVAL_PASS")
    print("CHOSEN_PROFILE", pick["chosen"]["profile"])
    print("CHOSEN_CAND_CAP", pick["chosen"]["cand_cap"])


if __name__ == "__main__":
    main()
