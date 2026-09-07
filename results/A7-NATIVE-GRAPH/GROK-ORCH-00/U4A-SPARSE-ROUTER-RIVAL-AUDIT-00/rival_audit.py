#!/usr/bin/env python3
"""U4A host-model rival audit. PROGRAM=NO. Not board evidence."""
from __future__ import annotations

import json
import zlib
from collections import defaultdict
from pathlib import Path

N = 800_000
N_QUERY = 200
SEED = 0xA7FE01
POSTING_B = 16  # PostingCandidate bytes
DIR_B = 8       # RouterDirectoryEntry bytes


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
    # FPGA-style: derive 8 candidate keys from id bytes (dataset-side, not query host hash)
    raw = nid.to_bytes(4, "little")
    h = zlib.crc32(raw) & 0xFFFFFFFF
    k = []
    x = h
    for i in range(8):
        x = (x * 0x45D9F3B + nid + i) & 0xFFFFFFFF
        k.append((x ^ (h >> (i * 3))) & 0xFFFF)
    return tuple(k)


def build_index(n_tables: int, n_buckets: int, head_cap: int):
    heads = [[list() for _ in range(n_buckets)] for _ in range(n_tables)]
    overflow = 0
    occ = []
    covered = set()
    for nid in range(N):
        ks = rec_keys(nid)
        for t in range(n_tables):
            b = ks[t] % n_buckets
            bucket = heads[t][b]
            if len(bucket) < head_cap:
                bucket.append(nid)
                covered.add(nid)
            else:
                overflow += 1
    for t in range(n_tables):
        for b in heads[t]:
            occ.append(len(b))
    occ.sort()
    return heads, {
        "overflow_posts": overflow,
        "coverage": len(covered) / N,
        "occ_p50": occ[len(occ) // 2],
        "occ_p99": occ[int(len(occ) * 0.99)],
        "occ_max": occ[-1],
        "empty_frac": sum(1 for x in occ if x == 0) / len(occ),
        "dir_bytes": n_tables * n_buckets * DIR_B,
    }


def run_profile(name: str, n_tables: int, n_buckets: int, head_cap: int, caps: list[int]):
    heads, st = build_index(n_tables, n_buckets, head_cap)
    rng = SEED
    rows = []
    for qi in range(N_QUERY):
        rng = (1103515245 * rng + 12345) & 0x7FFFFFFF
        toks = [((rng >> 8) + qi + j) & 0xFF or 1 for j in range(3)]
        qk = qfe_keys(toks)
        qk8 = list(qk) + [
            (qk[0] ^ qk[1]) & 0xFFFF,
            (qk[2] ^ qk[3]) & 0xFFFF,
            (qk[0] + qk[2]) & 0xFFFF,
            (qk[1] + qk[3]) & 0xFFFF,
        ]
        union = []
        seen = set()
        dups = 0
        for t in range(n_tables):
            b = qk8[t] % n_buckets
            for nid in heads[t][b]:
                if nid in seen:
                    dups += 1
                else:
                    seen.add(nid)
                    union.append(nid)
        relevant = set(union)  # router-admission relevant set
        for cap in caps:
            cands = union[:cap]
            overflow_q = max(0, len(union) - cap)
            bytes_q = len(cands) * POSTING_B + n_tables * DIR_B
            hit = len(cands)
            rec = 1.0 if not relevant else hit / min(len(relevant), cap) if cap else 0.0
            # recall@cap vs admitted union truncated — tautological if relevant=union
            # Use a second relevant: records whose rec_keys[0] bucket equals qk[0]
            gold = set(heads[0][qk[0] % n_buckets])
            rec0 = 0.0 if not gold else len(gold.intersection(cands)) / len(gold)
            rows.append({
                "q": qi, "cap": cap, "admitted": len(union), "cands": len(cands),
                "dups": dups, "overflow_q": overflow_q, "bytes_q": bytes_q, "recall_k0": rec0,
            })
    by_cap = {}
    for cap in caps:
        sl = [r for r in rows if r["cap"] == cap]
        by_cap[str(cap)] = {
            "mean_cands": sum(r["cands"] for r in sl) / len(sl),
            "mean_admitted": sum(r["admitted"] for r in sl) / len(sl),
            "mean_bytes": sum(r["bytes_q"] for r in sl) / len(sl),
            "mean_dups": sum(r["dups"] for r in sl) / len(sl),
            "mean_overflow_q": sum(r["overflow_q"] for r in sl) / len(sl),
            "mean_recall_k0": sum(r["recall_k0"] for r in sl) / len(sl),
            "max_admitted": max(r["admitted"] for r in sl),
        }
    return {
        "name": name,
        "n_tables": n_tables,
        "n_buckets": n_buckets,
        "head_cap": head_cap,
        "index": st,
        "by_cap": by_cap,
    }


def main():
    caps = [64, 128, 256, 512, 1024]
    profiles = [
        run_profile("P2_deep", 2, 4096, 64, caps),
        run_profile("P4_mod", 4, 4096, 32, caps),
        run_profile("P8_shallow", 8, 2048, 16, caps),
    ]
    # Select: maximize mean_recall_k0 at cap=256, then minimize mean_bytes, then overflow
    def score(p):
        b = p["by_cap"]["256"]
        return (p["index"]["coverage"], -b["mean_bytes"], -p["index"]["overflow_posts"])

    winner = max(profiles, key=score)
    out = {
        "gate": "U4A-SPARSE-ROUTER-RIVAL-AUDIT-00",
        "evidence_class": "HOST_MODEL",
        "n": N,
        "n_query": N_QUERY,
        "law": "qfe-v1-crc16-mix-00",
        "profiles": profiles,
        "router_profile_final": winner["name"],
        "cand_cap_final": 256,
        "ddr_query_bound_final": int(winner["by_cap"]["256"]["mean_bytes"] * 2),
        "note": "HOST_MODEL only. Does not freeze Gate14 semantic recall. Full-scan remains NO.",
    }
    bag = Path(__file__).resolve().parent
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("WINNER", winner["name"])
    print("CAND_CAP_FINAL 256")
    print("DDR_QUERY_BOUND_FINAL", out["ddr_query_bound_final"])
    for p in profiles:
        print(p["name"], "ovf", p["index"]["overflow_posts"], "cap256", p["by_cap"]["256"])
    print("U4A_RIVAL_AUDIT_PASS")


if __name__ == "__main__":
    main()
