#!/usr/bin/env python3
"""NG-02R Top-K oracle + vector generator (global Top-8).

Law: a7ng-topk-global-v1
Total order (better first):
  1) valid beats invalid
  2) among valid: higher score, then lower node_id, then lower lane
  3) among invalid (pad): lower node_id, then lower lane
"""
from __future__ import annotations

import argparse
import hashlib
import random
from pathlib import Path

N, K = 16, 8


def sort_key(c: tuple) -> tuple:
    v, s, i, x = c
    if v:
        return (0, -s, i, x)
    return (1, i, x, 0)


def oracle_topk(cands: list[tuple], k: int = K) -> list[tuple]:
    return sorted(cands, key=sort_key)[:k]


def beats(a: tuple, b: tuple) -> bool:
    av, as_, ai, ax = a
    bv, bs, bi, bx = b
    if av != bv:
        return av
    if av:
        if as_ != bs:
            return as_ > bs
        if ai != bi:
            return ai < bi
        return ax < bx
    if ai != bi:
        return ai < bi
    return ax < bx


def bitonic_topk(cands: list[tuple]) -> list[tuple]:
    """Reference of the silicon path: full bitonic sort → reverse top half."""
    arr = list(cands)

    def cas(i: int, j: int, direction: str) -> None:
        if direction == "asc":
            if beats(arr[i], arr[j]):
                arr[i], arr[j] = arr[j], arr[i]
        else:
            if beats(arr[j], arr[i]):
                arr[i], arr[j] = arr[j], arr[i]

    n = len(arr)
    kk = 2
    while kk <= n:
        j = kk // 2
        while j > 0:
            for i in range(n):
                l = i ^ j
                if l > i:
                    direction = "asc" if (i & kk) == 0 else "desc"
                    cas(i, l, direction)
            j //= 2
        kk *= 2
    return list(reversed(arr[8:16]))


def gen_vector(rng: random.Random) -> tuple[list[tuple], list[tuple]]:
    cands: list[tuple] = []
    for lane in range(N):
        valid = rng.random() > 0.18
        score = rng.randint(-32768, 32767)
        node_id = rng.randint(0, 0xFFFFFFFF)
        if rng.random() < 0.15 and lane > 0:
            # inject score / id ties
            src = cands[rng.randrange(lane)]
            if rng.random() < 0.5:
                score = src[1]
            else:
                node_id = src[2]
                if rng.random() < 0.3:
                    score = src[1]
        cands.append((valid, score, node_id & 0xFFFFFFFF, lane))
    top = oracle_topk(cands)
    # Self-check bitonic model == oracle (silicon path)
    assert bitonic_topk(cands) == top
    return cands, top


def write_vectors(path: Path, n: int, seed: int) -> dict:
    path.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed)
    lines = [f"{n}\n"]
    for _ in range(n):
        cands, top = gen_vector(rng)
        mask = 0
        for lane, c in enumerate(cands):
            if c[0]:
                mask |= 1 << lane
        parts = [f"{mask:04x}"]
        for c in cands:
            parts.append(f"{c[1]} {c[2]:08x}")
        for c in top:
            parts.append(f"{c[1]} {c[2]:08x}")
        lines.append(" ".join(parts) + "\n")
    text = "".join(lines)
    path.write_text(text, encoding="utf-8")
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    return {"n": n, "seed": seed, "sha256": digest, "path": str(path)}


def compare_research() -> dict:
    """Comparator / latency / notes for the three FANNS-aligned options."""
    # Bitonic 16: 10 stages × 8 CAS = 80 CAS (combinational depth ~10 CAS)
    bitonic = {
        "name": "full_bitonic_16_to_8",
        "comparators": 80,
        "logic_depth_cas": 10,
        "cycles_registered": 1,
        "ordered_top8": True,
        "notes": "Exact; take ranked[15:8] reversed after ascending bitonic.",
    }
    # Exact partial selection (Batcher selection / knockout to K then sort K):
    # For N=16 K=8, lower bound ~ N*logK + K*logK scale; practical OE-merge
    # select nets still ~60-70 CAS and need a follow-on K-sort for ordered Top-8.
    partial = {
        "name": "exact_partial_selection_network",
        "comparators": "~60-72 + 19 K-sort",
        "logic_depth_cas": "~9-12",
        "cycles_registered": 1,
        "ordered_top8": "after extra K-sort",
        "notes": "Saves little at N=16; harder to audit vs oracle.",
    }
    systolic = {
        "name": "systolic_priority_queue_multi_input",
        "comparators": "8 per insert × 16 inserts streaming",
        "logic_depth_cas": 1,
        "cycles_registered": ">=16 (or folded)",
        "ordered_top8": True,
        "notes": "Multi-cycle; fights II=1 batch of 16 scorer lanes.",
    }
    return {
        "selected": "full_bitonic_16_to_8",
        "reason": (
            "N=16 K=8 one-cycle registered Top-8 with ordered output and "
            "trivial Python/RTL identity; systolic PQ multi-cycle; partial "
            "net savings are small and audit cost is higher."
        ),
        "options": [bitonic, partial, systolic],
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=100_000)
    ap.add_argument("--seed", type=int, default=0xA7020201)
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("results/A7-NATIVE-GRAPH/NG-02R-TOPK/vectors/topk_100k.txt"),
    )
    args = ap.parse_args()
    meta = write_vectors(args.out, args.n, args.seed)
    research = compare_research()
    print("WROTE", meta)
    print("SELECTED", research["selected"])
    print("REASON", research["reason"])


if __name__ == "__main__":
    main()
