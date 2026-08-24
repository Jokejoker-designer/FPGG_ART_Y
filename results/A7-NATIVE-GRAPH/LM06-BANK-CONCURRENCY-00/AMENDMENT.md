# AMENDMENT — LM06-BANK-CONCURRENCY-00 (independent human audit)

**Date:** 2026-08-24  
**Trigger:** Independent review (not RESULTS/CLOSEOUT as default authority)  
**Verdict adopted:** `PASS_NARROW` / **CLOSEOUT_AMEND_REQUIRED** → applied below  
**Main loop / Codex Attempt 10 / `ddr_cue_soa_bench_01`:** not modified by this amendment

---

## Corrections applied

| # | Issue | Fix |
|---|-------|-----|
| 1 | `CORE_snap` `N_capacity=1`, `topology_headroom=1` | **REJECTED.** `4096×16=65536` bits → `⌈65536/36864⌉=2`. Headroom **0**. |
| 2 | D1 framed as “topology waste” | Rewritten as **CROSS-RESOURCE** BRAM→LUTRAM, potential **−2 BRAM**, ~1K+ LUT class, `NEEDS_SYNTH` |
| 3 | “92% FWD = semantic dual-port demand” | Downgraded: FACT is `aaddr≠aaddr_b` rate; **ACCEPT_NARROW** that TDP needed in some FSM states; semantic dual-consume needs gated counters |
| 4 | CORE weight “measured bandwidth” | Labeled **ACCEPT_STATIC_ONLY** (`POST_ROUTE_DCP`+`RTL_STATIC`); XSim was `SIM_FULL=1` |
| 5 | TSV provenance | Labeled **`CURATED_DERIVATION`** (hard-coded from phys+RTL facts; not auto-derived from DCP rows). Script gains fail-fast count asserts. |
| 6 | Closeout `TRACE_COMPLETE_LIFETIME_ONLY_HEADROOM` | Renamed → **`TRACE_COMPLETE_PORT_TOPOLOGY_CLOSED_LIFETIME_OPEN`** |
| 7 | Next candidate F1 first | **Reordered:** next research unknown = **BOARD tensor reachability (34 BRAM)** before F1 |

---

## What still stands (ACCEPT)

- CORE/BOARD physical-family split (98 + 34)
- CORE act/weight shape ≈ native width×depth; no free bank fold
- Naive parity / simple bank collapse is not the large lever
- Activation needs true dual-port capability in at least some states (ATTQK/ADD evidence)

## What remains OPEN

- Complete lifetime behavior
- Dynamic silicon-TILE weight behavior
- BOARD pingpong lifetime exclusivity
- Necessity of BOARD tensor subsystem on LM06 causal output path

---

## NEXT RESEARCH UNKNOWN (human-authorized gate only)

```text
LM06-BOARD-TENSOR-REACHABILITY-01
ONE UNKNOWN:
  Do tile_weight_pingpong + tile_activation participate in the
  causal path that produces frozen LM06 BOARD_PASS token/output?
```

Do **not** auto-start. Do **not** open F1 until reachability returns A/B/C.
