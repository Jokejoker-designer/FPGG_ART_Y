# CLOSEOUT — E1-AB-COFIT-PARALLEL-00-CLOCK80

**Gate:** E1-AB-COFIT-PARALLEL-00 existence trial (80 ns clock)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** POST_ROUTE_OOC  
**Verdict:** **PASS** (timing)  
**Marker:** *(not issued — existence trial only; no bitstream)*

## Hypothesis

| Field | Value |
|-------|-------|
| H_CANDIDATE | WNS ≥ 0 at 80.000 ns period (~12.5 MHz); 65 ns marginal miss (+0.858 ns needed) closes at 80 ns |
| FALSIFIER | WNS still negative at 80 ns → document timing floor only; Option C pipeline remains DEFER |
| **Outcome** | **H_CANDIDATE CONFIRMED** — WNS = +3.648 ns |

## Build

| Item | Value |
|------|-------|
| Script | `vivado/tcl/build_native_v1_ab_postroute_e1_80ns.tcl` |
| Vivado | 2026.1 (`C:\2026.1\Vivado\bin\vivado.bat`) |
| Top | `a7ng_native_v1_ab_core` OOC |
| Generic | `SIM_FULL=0` |
| Define | `SYNTHESIS A7LM06_SNAP_LUTRAM_BIND` |
| Part | `xc7a100tcsg324-1` |
| Clock | **80.000 ns** (~12.500 MHz) |
| Build dir | `build/native_v1_board_parallel_e1_80ns/` |
| Exit code | 0 (`route_ok=1`) |
| Bitstream | **NOT generated** (forbidden) |

## Gate metrics (post-route)

| Metric | Measured | Limit | Gate |
|--------|----------|-------|------|
| BRAM RAMB36 | 96 | ≤ 135 | **PASS** |
| BRAM RAMB18 | 0 | — | — |
| BRAM36-equiv | 96 | ≤ 135 | **PASS** |
| WNS | **+3.648 ns** | ≥ 0 ns | **PASS** |
| TNS | **0.000 ns** | 0 | **PASS** |
| WHS | 0.026 ns | report | OK |
| THS | 0.000 ns | report | OK |
| Failing endpoints | 0 / 117103 | 0 | **PASS** |
| DSP48E1 | 19 | 0 preferred | informational |

## Comparison vs 65 ns run (E1-AB-COFIT-PARALLEL-00-CLOCK65)

| Metric | 65 ns run | 80 ns run | Δ |
|--------|-----------|-----------|---|
| WNS | −0.858 ns | +3.648 ns | +4.506 ns |
| TNS | −104.814 ns | 0.000 ns | +104.814 ns |
| Failing endpoints | 278 | 0 | −278 |
| BRAM RAMB36 | 96 | 96 | 0 |
| Implied critical path | ~65.9 ns | ~76.4 ns | placement variance |

Relaxing clock from 65 ns → 80 ns closes all setup violations. **Option A (clock-only co-fit) is sufficient at 80 ns** without pipeline.

## E2 / ALLOW_PROGRAM note

**E2 operating clock = 12.5 MHz** (80.000 ns period) for ALLOW_PROGRAM eligibility. Pipeline (Option C) remains **DEFER** per Grok DECIDE.

## Utilization (post-route)

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUT | 50096 | 63400 | 79.02 |
| LUTRAM | 2144 | 19000 | 11.28 |
| FF | 49821 | 126800 | 39.29 |
| BRAM (RAMB36) | 96 | 135 | 71.11 |
| DSP48E1 | 19 | 240 | 7.92 |

## DCP SHA256

| Artifact | SHA256 |
|----------|--------|
| `ab_post_synth.dcp` | `18355323BFF67759F4946AE388D1CE4EE0A3EB19D31B8981CAA528BF03294FDC` |
| `ab_post_route.dcp` | `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |

## Artifacts

```text
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_synth.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_route.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_util_hier.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_util_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_timing_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_route_status.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_postroute_metrics.txt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK80/vivado_batch.log
```

## Notes

- OOC mode: no pin LOC constraints; slack reflects logical path without top-level clock-tree placement.
- BRAM co-fit unchanged at 96 RAMB36 (≤ 135 envelope).
- Grok DECIDE E1: this is the one additional existence-class trial after CLOCK65 marginal miss.
- R6 worktree untouched.
