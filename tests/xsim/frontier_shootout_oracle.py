#!/usr/bin/env python3
"""frontier_shootout_oracle.py — identical-workload A/B/C frontier shootout.

Gate: frontier_shootout
UNKNOWN: under identical workload, which of {bucket, systolic PQ, two-level}
         wins on preregistered metrics without changing Top-8 global law?

UNIT: query seed (not cycles-as-queries).
CONTROL: a7ng-topk-global-v1 SHA; NG-02R-FLOW bucket SHA; frozen bits untouched.

METRICS (preregistered BEFORE waves — do not retune after):
  M1 order_agree      : fraction of accepted pops matching exact best-first oracle
  M2 recall_proxy_at8 : |DUT first-8 ∩ oracle first-8| / 8  (mean over queries)
  M3 cycles_per_query : push+drain cycles for that query bag (mean)
  M4 enq_per_cyc      : accepted pushes / total cycles
  M5 deq_per_cyc      : valid pops / total cycles
  M6 overflow_count   : rejected pushes (full)
  M7 lut_ff           : OOC synth if available (else NA)
  M8 wns              : routed if available (else NA — synth-only declared)

Does not declare BOARD_PASS. Does not change Top-8 law.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
import struct
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results" / "A7-NATIVE-GRAPH" / "FRONTIER-SHOOTOUT"

MASTER_SEED = 0xF5022201
N_QUERIES = 64
PUSHES_PER_QUERY = 48
CAP = 64  # capacity parity: A uses NBINS=16 DEPTH=4; B DEPTH=64; C 4x16
RECALL_K = 8

TOPK_LAW_SHA = "F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636"
BUCKET_CTRL_SHA = "CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest().upper()


def beats(sa: int, ida: int, sb: int, idb: int) -> bool:
    if sa != sb:
        return sa > sb
    return ida < idb


@dataclass
class Item:
    score: int
    id: int


@dataclass
class ArmResult:
    name: str
    pops: List[Item] = field(default_factory=list)
    accepted: int = 0
    overflow: int = 0
    cycles: int = 0
    enq: int = 0
    deq: int = 0


class ExactOracle:
    """Exact best-first (max-heap by score, then lower id)."""

    def __init__(self, cap: int = CAP):
        self.cap = cap
        self.items: List[Item] = []

    def push(self, it: Item) -> bool:
        if len(self.items) >= self.cap:
            return False
        self.items.append(it)
        return True

    def pop(self) -> Optional[Item]:
        if not self.items:
            return None
        best_i = 0
        for i in range(1, len(self.items)):
            if beats(self.items[i].score, self.items[i].id,
                     self.items[best_i].score, self.items[best_i].id):
                best_i = i
        return self.items.pop(best_i)

    def empty(self) -> bool:
        return not self.items


class BucketFrontier:
    """Behavioral match of a7ng_frontier_buckets (NBINS=16, DEPTH=4 → CAP=64)."""

    def __init__(self, nbins: int = 16, depth: int = 4):
        self.nbins = nbins
        self.depth = depth
        self.bins: List[List[Item]] = [[] for _ in range(nbins)]

    def _bin(self, score: int) -> int:
        # score_u = score + 32768; bin = score_u[15:12]
        score_u = (score + 32768) & 0xFFFF
        return (score_u >> 12) & 0xF

    def push(self, it: Item) -> bool:
        b = self._bin(it.score)
        if len(self.bins[b]) >= self.depth:
            return False
        self.bins[b].append(it)
        return True

    def pop(self) -> Optional[Item]:
        for b in range(self.nbins - 1, -1, -1):
            if self.bins[b]:
                return self.bins[b].pop(0)  # FIFO within bin
        return None

    def empty(self) -> bool:
        return all(len(b) == 0 for b in self.bins)

    def count(self) -> int:
        return sum(len(b) for b in self.bins)


class SystolicPQ:
    """Exact sorted list (head = best). Behavioral twin of arm B."""

    def __init__(self, depth: int = CAP):
        self.depth = depth
        self.items: List[Item] = []

    def push(self, it: Item) -> bool:
        if len(self.items) >= self.depth:
            return False
        insert_at = len(self.items)
        for i, cur in enumerate(self.items):
            if beats(it.score, it.id, cur.score, cur.id):
                insert_at = i
                break
        self.items.insert(insert_at, it)
        return True

    def pop(self) -> Optional[Item]:
        if not self.items:
            return None
        return self.items.pop(0)

    def empty(self) -> bool:
        return not self.items


class TwoLevel:
    """Local sorted PQs + global best-of-heads. Behavioral twin of arm C."""

    def __init__(self, n_local: int = 4, local_depth: int = 16):
        self.n_local = n_local
        self.local_depth = local_depth
        self.locals: List[List[Item]] = [[] for _ in range(n_local)]

    def _lane(self, id_: int) -> int:
        return id_ & (self.n_local - 1)

    def push(self, it: Item) -> bool:
        lane = self._lane(it.id)
        loc = self.locals[lane]
        if len(loc) >= self.local_depth:
            return False
        insert_at = len(loc)
        for i, cur in enumerate(loc):
            if beats(it.score, it.id, cur.score, cur.id):
                insert_at = i
                break
        loc.insert(insert_at, it)
        return True

    def pop(self) -> Optional[Item]:
        best_l = None
        for l, loc in enumerate(self.locals):
            if not loc:
                continue
            if best_l is None or beats(
                loc[0].score, loc[0].id,
                self.locals[best_l][0].score, self.locals[best_l][0].id
            ):
                best_l = l
        if best_l is None:
            return None
        return self.locals[best_l].pop(0)

    def empty(self) -> bool:
        return all(len(l) == 0 for l in self.locals)


def make_query_bag(qseed: int, n: int = PUSHES_PER_QUERY) -> List[Item]:
    """One experimental unit: a query's candidate bag (deterministic from qseed)."""
    rng = random.Random(qseed)
    mode = qseed % 4
    items: List[Item] = []
    for k in range(n):
        if mode == 0:
            # Uniform scores
            score = rng.randint(-20000, 20000)
        elif mode == 1:
            # Clustered into few bins (bucket stress)
            band = rng.choice([0, 1, 14, 15])
            score = (band << 12) - 32768 + rng.randint(0, 200)
        elif mode == 2:
            # Many ties (tie-break stress)
            score = rng.choice([100, 500, 1000, 5000])
        else:
            # Adversarial: descending then ascending interleaved
            score = (30000 - 600 * k) if (k % 2 == 0) else (-1000 + 40 * k)
            score = max(-32768, min(32767, score))
        nid = (qseed & 0xFFFF) << 16 | (k & 0xFFFF)
        # Ensure unique ids
        items.append(Item(score=int(score), id=int(nid & 0xFFFFFFFF)))
    return items


def run_arm(arm_name: str, arm, bag: List[Item]) -> ArmResult:
    """Push-all-then-drain protocol (push XOR pop). Same for every arm."""
    r = ArmResult(name=arm_name)
    # Push phase
    for it in bag:
        r.cycles += 1
        if arm.push(it):
            r.accepted += 1
            r.enq += 1
        else:
            r.overflow += 1
    # Drain phase
    while True:
        it = arm.pop()
        r.cycles += 1
        if it is None:
            break
        r.pops.append(it)
        r.deq += 1
    return r


def run_oracle(bag: List[Item]) -> ArmResult:
    """Oracle uses same capacity and accepts same push successes as ExactOracle
    with CAP — but for order agreement we compare against exact order of
    *items that the arm accepted*. Per-arm oracle rebuilt from accepted set.
    """
    return run_arm("oracle", ExactOracle(CAP), bag)


def order_agree(dut_pops: List[Item], accepted: List[Item]) -> float:
    """Replay exact best-first on the accepted multiset; compare sequences."""
    oracle = ExactOracle(cap=max(CAP, len(accepted) + 1))
    for it in accepted:
        assert oracle.push(it)
    gold: List[Item] = []
    while True:
        it = oracle.pop()
        if it is None:
            break
        gold.append(it)
    if not gold:
        return 1.0 if not dut_pops else 0.0
    n = min(len(gold), len(dut_pops))
    match = sum(
        1 for i in range(n)
        if dut_pops[i].score == gold[i].score and dut_pops[i].id == gold[i].id
    )
    # Penalize length mismatch
    denom = max(len(gold), len(dut_pops), 1)
    return match / denom


def recall_proxy_at_k(dut_pops: List[Item], gold_pops: List[Item], k: int = RECALL_K) -> float:
    """Set overlap of first-K pops vs exact best-first arm on same bag (M2)."""
    gold = gold_pops[:k]
    if not gold:
        return 1.0
    gset = {(g.score, g.id) for g in gold}
    dset = {(d.score, d.id) for d in dut_pops[:k]}
    return len(gset & dset) / float(len(gset))


def accepted_items(arm_name: str, bag: List[Item]) -> List[Item]:
    """Re-simulate pushes only to recover accepted list in push order."""
    if arm_name == "A_bucket":
        arm = BucketFrontier(16, 4)
    elif arm_name == "B_systolic":
        arm = SystolicPQ(CAP)
    elif arm_name == "C_twolevel":
        arm = TwoLevel(4, 16)
    else:
        raise ValueError(arm_name)
    acc: List[Item] = []
    for it in bag:
        if arm.push(it):
            acc.append(it)
    return acc


def shootout() -> dict:
    arms = {
        "A_bucket": lambda: BucketFrontier(16, 4),
        "B_systolic": lambda: SystolicPQ(CAP),
        "C_twolevel": lambda: TwoLevel(4, 16),
    }
    per_arm = {
        name: {
            "order_agree": [],
            "recall_proxy_at8": [],
            "cycles_per_query": [],
            "enq": 0,
            "deq": 0,
            "overflow": 0,
            "cycles_total": 0,
            "queries": 0,
        }
        for name in arms
    }
    query_rows = []

    for qi in range(N_QUERIES):
        qseed = (MASTER_SEED ^ (qi * 0x9E3779B9)) & 0xFFFFFFFF
        bag = make_query_bag(qseed)
        row = {"query_idx": qi, "qseed": f"0x{qseed:08X}"}
        gold = run_oracle(bag)
        for name, factory in arms.items():
            res = run_arm(name, factory(), bag)
            acc = accepted_items(name, bag)
            oa = order_agree(res.pops, acc)
            rp = recall_proxy_at_k(res.pops, gold.pops, RECALL_K)
            per_arm[name]["order_agree"].append(oa)
            per_arm[name]["recall_proxy_at8"].append(rp)
            per_arm[name]["cycles_per_query"].append(res.cycles)
            per_arm[name]["enq"] += res.enq
            per_arm[name]["deq"] += res.deq
            per_arm[name]["overflow"] += res.overflow
            per_arm[name]["cycles_total"] += res.cycles
            per_arm[name]["queries"] += 1
            row[f"{name}_order_agree"] = round(oa, 6)
            row[f"{name}_recall8"] = round(rp, 6)
            row[f"{name}_cycles"] = res.cycles
            row[f"{name}_ovf"] = res.overflow
        query_rows.append(row)

    summary = {}
    for name, st in per_arm.items():
        nq = st["queries"]
        ct = max(st["cycles_total"], 1)
        summary[name] = {
            "M1_order_agree_mean": sum(st["order_agree"]) / nq,
            "M2_recall_proxy_at8_mean": sum(st["recall_proxy_at8"]) / nq,
            "M3_cycles_per_query_mean": sum(st["cycles_per_query"]) / nq,
            "M4_enq_per_cyc": st["enq"] / ct,
            "M5_deq_per_cyc": st["deq"] / ct,
            "M6_overflow_count": st["overflow"],
            "M7_lut_ff": "NA_PENDING_OOC",
            "M8_wns": "NA_SYNTH_ONLY_DECLARED",
            "queries": nq,
            "cycles_total": st["cycles_total"],
        }

    # Winner by primary metric M1, tie-break M2, then M3 (lower better)
    ranking = sorted(
        summary.keys(),
        key=lambda n: (
            -summary[n]["M1_order_agree_mean"],
            -summary[n]["M2_recall_proxy_at8_mean"],
            summary[n]["M3_cycles_per_query_mean"],
        ),
    )
    return {
        "gate": "frontier_shootout",
        "master_seed": f"0x{MASTER_SEED:08X}",
        "n_queries": N_QUERIES,
        "pushes_per_query": PUSHES_PER_QUERY,
        "cap": CAP,
        "unit": "query_seed",
        "summary": summary,
        "ranking_by_M1_M2_M3": ranking,
        "winner_primary": ranking[0],
        "query_rows": query_rows,
    }


def write_vectors(out_dir: Path) -> Path:
    """Text vectors + golden pop streams for XSim RTL check."""
    vec = out_dir / "workload_vectors.txt"
    gold_b = out_dir / "golden_B_pops.txt"
    gold_c = out_dir / "golden_C_pops.txt"
    with vec.open("w", encoding="utf-8") as f, \
         gold_b.open("w", encoding="utf-8") as fb, \
         gold_c.open("w", encoding="utf-8") as fc:
        f.write(f"# MASTER_SEED=0x{MASTER_SEED:08X} N_QUERIES={N_QUERIES} "
                f"PUSHES={PUSHES_PER_QUERY} CAP={CAP}\n")
        fb.write(f"# golden B systolic pops\n")
        fc.write(f"# golden C twolevel pops\n")
        for qi in range(N_QUERIES):
            qseed = (MASTER_SEED ^ (qi * 0x9E3779B9)) & 0xFFFFFFFF
            bag = make_query_bag(qseed)
            f.write(f"Q {qi} 0x{qseed:08X} {len(bag)}\n")
            for it in bag:
                f.write(f"{it.score} {it.id}\n")
            rb = run_arm("B_systolic", SystolicPQ(CAP), bag)
            rc = run_arm("C_twolevel", TwoLevel(4, 16), bag)
            fb.write(f"Q {qi} {len(rb.pops)} {rb.overflow}\n")
            for it in rb.pops:
                fb.write(f"{it.score} {it.id}\n")
            fc.write(f"Q {qi} {len(rc.pops)} {rc.overflow}\n")
            for it in rc.pops:
                fc.write(f"{it.score} {it.id}\n")
    return vec


def control_check() -> dict:
    topk = ROOT / "rtl" / "native_graph" / "topk" / "a7ng_topk.sv"
    bucket = ROOT / "rtl" / "native_graph" / "frontier" / "a7ng_frontier_buckets.sv"
    tsha = sha256_file(topk)
    bsha = sha256_file(bucket)
    return {
        "topk_law_sha": tsha,
        "topk_law_match": tsha == TOPK_LAW_SHA,
        "bucket_ctrl_sha": bsha,
        "bucket_ctrl_match": bsha == BUCKET_CTRL_SHA,
        "expected_topk": TOPK_LAW_SHA,
        "expected_bucket": BUCKET_CTRL_SHA,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=OUT)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    # Preregister stamp (metrics locked)
    prereg = args.out / "PREREGISTER.md"
    if not prereg.exists():
        prereg.write_text(
            "# FRONTIER-SHOOTOUT preregistration\n\n"
            f"Master seed: `0x{MASTER_SEED:08X}`\n"
            f"Queries (units): {N_QUERIES}\n"
            f"Pushes/query: {PUSHES_PER_QUERY}\n"
            f"Capacity: {CAP}\n\n"
            "Metrics locked before waves:\n"
            "- M1 order_agree\n- M2 recall_proxy_at8\n"
            "- M3 cycles_per_query\n- M4 enq_per_cyc\n"
            "- M5 deq_per_cyc\n- M6 overflow_count\n"
            "- M7 lut/ff (OOC if cheap)\n- M8 wns (NA if synth-only)\n\n"
            "Falsifier: no comparison table; or Top-8 / flow law regresses.\n",
            encoding="utf-8",
        )

    ctrl = control_check()
    (args.out / "CONTROL_SHA.json").write_text(json.dumps(ctrl, indent=2), encoding="utf-8")
    if not ctrl["topk_law_match"] or not ctrl["bucket_ctrl_match"]:
        print("CONTROL_FAIL", json.dumps(ctrl))
        return 2

    result = shootout()
    vec = write_vectors(args.out)

    # Summary table
    table_path = args.out / "COMPARISON_TABLE.csv"
    with table_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "arm", "M1_order_agree", "M2_recall8", "M3_cyc_per_q",
            "M4_enq_per_cyc", "M5_deq_per_cyc", "M6_overflow",
            "M7_lut_ff", "M8_wns",
        ])
        for name, s in result["summary"].items():
            w.writerow([
                name,
                f"{s['M1_order_agree_mean']:.6f}",
                f"{s['M2_recall_proxy_at8_mean']:.6f}",
                f"{s['M3_cycles_per_query_mean']:.3f}",
                f"{s['M4_enq_per_cyc']:.6f}",
                f"{s['M5_deq_per_cyc']:.6f}",
                s["M6_overflow_count"],
                s["M7_lut_ff"],
                s["M8_wns"],
            ])

    per_q = args.out / "PER_QUERY.csv"
    if result["query_rows"]:
        keys = list(result["query_rows"][0].keys())
        with per_q.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=keys)
            w.writeheader()
            w.writerows(result["query_rows"])

    # Drop bulky rows from json summary artifact
    slim = {k: v for k, v in result.items() if k != "query_rows"}
    slim["vector_file"] = str(Path(vec).resolve().relative_to(ROOT.resolve())).replace("\\", "/")
    slim["control"] = ctrl
    (args.out / "SHOOTOUT_SUMMARY.json").write_text(
        json.dumps(slim, indent=2), encoding="utf-8"
    )

    print("FRONTIER_SHOOTOUT_PY_PASS")
    print("winner", result["winner_primary"])
    print("ranking", result["ranking_by_M1_M2_M3"])
    for name, s in result["summary"].items():
        print(
            f"{name}: M1={s['M1_order_agree_mean']:.4f} "
            f"M2={s['M2_recall_proxy_at8_mean']:.4f} "
            f"M3={s['M3_cycles_per_query_mean']:.1f} "
            f"ovf={s['M6_overflow_count']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
