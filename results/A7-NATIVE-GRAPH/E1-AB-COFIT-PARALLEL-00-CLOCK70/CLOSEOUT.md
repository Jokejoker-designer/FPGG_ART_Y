# CLOSEOUT — E1-AB-COFIT-PARALLEL-00-CLOCK70

**Gate:** E1-AB-COFIT-PARALLEL-00 falsifier (70 ns clock)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** POST_ROUTE_OOC  
**Verdict:** **PASS** (timing)  
**Marker:** `E1_AB_COFIT_PARALLEL_00_CLOCK70_POSTROUTE_PASS`

## Hypothesis

| Field | Value |
|-------|-------|
| H_CANDIDATE | WNS ≥ 0 at 70.000 ns period (~14.3 MHz); 5 ns margin over 65 ns miss closes −0.858 ns debt |
| FALSIFIER | WNS still negative at 70 ns → pipeline or further clock reduction required |
| **Outcome** | **H_CANDIDATE CONFIRMED** — WNS = +0.519 ns |

## Build

| Item | Value |
|------|-------|
| Script | `vivado/tcl/build_native_v1_ab_postroute_e1_70ns.tcl` |
| Vivado | 2026.1 (`C:\2026.1\Vivado\bin\vivado.bat`) |
| Top | `a7ng_native_v1_ab_core` OOC |
| Generic | `SIM_FULL=0` |
| Define | `SYNTHESIS A7LM06_SNAP_LUTRAM_BIND` |
| Part | `xc7a100tcsg324-1` |
| Clock | **70.000 ns** (~14.286 MHz) |
| Build dir | `build/native_v1_board_parallel_e1_70ns/` |
| Exit code | 0 (`route_ok=1`) |
| Bitstream | **NOT generated** (forbidden) |

## Gate metrics (post-route)

| Metric | Measured | Limit | Gate |
|--------|----------|-------|------|
| BRAM RAMB36 | 96 | ≤ 135 | **PASS** |
| BRAM RAMB18 | 0 | — | — |
| BRAM36-equiv | 96 | ≤ 135 | **PASS** |
| WNS | **+0.519 ns** | ≥ 0 ns | **PASS** |
| TNS | **0.000 ns** | 0 | **PASS** |
| WHS | 0.066 ns | report | OK |
| THS | 0.000 ns | report | OK |
| Failing endpoints | 0 / 117103 | 0 | **PASS** |
| DSP48E1 | 19 | 0 preferred | informational |

## Comparison vs 65 ns run (E1-AB-COFIT-PARALLEL-00-CLOCK65)

| Metric | 65 ns run | 70 ns run | Δ |
|--------|-----------|-----------|---|
| WNS | −0.858 ns | +0.519 ns | +1.377 ns |
| TNS | −104.814 ns | 0.000 ns | +104.814 ns |
| Failing endpoints | 278 | 0 | −278 |
| BRAM RAMB36 | 96 | 96 | 0 |
| Implied critical path | ~65.9 ns | ~69.5 ns | +3.6 ns (placement variance) |

Relaxing clock from 65 ns → 70 ns closes the marginal miss. **Option A (clock-only co-fit at 70 ns) is sufficient** for E2 existence clock selection without pipeline RTL.

## Utilization (post-route)

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUT | 50105 | 63400 | 79.03 |
| LUTRAM | 2144 | 19000 | 11.28 |
| FF | 49821 | 126800 | 39.29 |
| BRAM (RAMB36) | 96 | 135 | 71.11 |
| DSP48E1 | 19 | 240 | 7.92 |

## DCP SHA256

| Artifact | SHA256 |
|----------|--------|
| `ab_post_synth.dcp` | `C2C51B67FF20E408C4D51229B1265956A9B3CB8C5CA0672EF9C18C75BCFA23D7` |
| `ab_post_route.dcp` | `9B14CC8D47842C672378B84BD3514701BCBD3FFB8941D892E56A7B6C23A0ED08` |

## Artifacts

```text
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_post_synth.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_post_route.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_util_hier.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_util_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_timing_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_route_status.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/ab_postroute_metrics.txt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK70/vivado_batch.log
```

## Notes

- OOC mode: no pin LOC constraints; slack reflects logical path without top-level clock-tree placement.
- BRAM co-fit unchanged at 96 RAMB36 (≤ 135 envelope).
- Grok DECIDE Option A: 70 ns clock falsifier **supports E2 existence clock selection** at ~14.3 MHz.
- R6 lane untouched. No pipeline RTL implemented.
