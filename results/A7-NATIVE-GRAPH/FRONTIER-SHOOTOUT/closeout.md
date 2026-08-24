# FRONTIER-SHOOTOUT closeout

**Gate:** `frontier_shootout`  
**Agent:** `a7-ng-topk-frontier`  
**Result:** PASS (engineering shootout — not BOARD_PASS)  
**Date:** 2026-08-22  
**Board:** Arty A7-100T (OOC synth only; no silicon)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Current frontier is coarse bucket priority (prototype), not proven vs exact best-first |
| UNKNOWN | Under identical workload, which of {bucket, systolic PQ, two-level} wins on preregistered metrics without changing Top-8 global law? |
| H_CANDIDATE | Measurable shootout selects architecture by numbers not taste |
| H_RIVAL | Workload confounds / single-seed pseudoreplication |
| FALSIFIER | No archived comparison table; or Top-8 / flow law regresses |
| UNIT | Query seed / query bag (N=64), not cycles-as-queries |
| CONTROL | `a7ng-topk-global-v1` SHA; NG-02R-FLOW bucket SHA; frozen bits untouched |
| METRICS | M1–M8 preregistered in `PREREGISTER.md` before waves |

## Arms (identical workload)

| Arm | RTL | Capacity |
|-----|-----|----------|
| A bucket | `a7ng_frontier_buckets` DEPTH=4 × 16 bins | 64 |
| B systolic PQ | `a7ng_frontier_systolic_pq` DEPTH=64 | 64 |
| C two-level | `a7ng_frontier_twolevel` 4×16 local + global merge | 64 |

Workload: master seed `0xF5022201`, 64 queries × 48 pushes, push-then-drain, push XOR pop.

## Comparison (archived)

See `COMPARISON_TABLE.csv`.

| Arm | M1 order | M2 recall@8 | M3 cyc/q | M6 ovf | M7 LUT | M7 FF |
|-----|----------|-------------|----------|--------|--------|-------|
| A_bucket | 0.515 | 0.650 | 71.5 | 1631 | 1169 | 3242 |
| B_systolic | **1.000** | **1.000** | 97.0 | 0 | **5848** | 3130 |
| C_twolevel | **1.000** | **1.000** | 97.0 | 0 | 7936 | 3150 |

**Ranking (M1 → M2 → M3 → M7 LUT):** B_systolic ≈ C_twolevel ≫ A_bucket on correctness; among exact arms, **B wins on LUT** (5848 < 7936).  
A is cheapest but loses exact best-first (coarse bins + FIFO-in-bin) and overflows under CAP-matched depth.

**Verdict (numbers, not taste):** Prefer **B systolic PQ** for exact best-first at CAP=64 on this bag; C is functionally tied but denser; keep A only as cheap prototype / NG-02R-FLOW control.

## Controls (no regression)

| Artifact | SHA256 | Status |
|----------|--------|--------|
| `a7ng_topk.sv` (`a7ng-topk-global-v1`) | `F671FCB1…AA197636` | MATCH control |
| `a7ng_frontier_buckets.sv` (NG-02R-FLOW) | `CE38FEC3…ACDD2C565` | MATCH control (untouched) |

## Tests

```text
python tests/xsim/frontier_shootout_oracle.py  → FRONTIER_SHOOTOUT_PY_PASS
xvlog/xelab/xsim tb_a7ng_frontier_shootout     → A7NG_FRONTIER_SHOOTOUT_XSIM_PASS queries=64
vivado OOC synth (3 arms)                      → FRONTIER_SHOOTOUT_OOC_DONE
```

## Explicit non-claims

- Not BOARD_PASS  
- Did not change global Top-8 law  
- Did not integrate TermGen / BRAM-WM / TRAIN-V2 / HNSW / more PE  
- Did not overwrite frozen A0.3 / 01R / 02M / LM-06 bits  
- M8 WNS = NA (synth-only declared before waves)  
- Evidence_class = PYTEST_BEHAVIORAL + XSIM + OOC_SYNTH ≠ board

## NEXT

Parent `--dispatch` after auditor; queue next OPEN (not self-declared).
