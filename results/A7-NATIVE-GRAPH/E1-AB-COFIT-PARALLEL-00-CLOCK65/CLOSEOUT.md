# CLOSEOUT — E1-AB-COFIT-PARALLEL-00-CLOCK65

**Gate:** E1-AB-COFIT-PARALLEL-00 falsifier (65 ns clock)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** POST_ROUTE_OOC  
**Verdict:** **FAIL** (timing)  
**Marker:** *(not issued — WNS < 0)*

## Hypothesis

| Field | Value |
|-------|-------|
| H_CANDIDATE | WNS ≥ 0 at 65.000 ns period (~15.4 MHz); ~58 ns critical path fits |
| FALSIFIER | WNS still negative at 65 ns → pipeline required (Option C) |
| **Outcome** | **FALSIFIER CONFIRMED** — WNS = −0.858 ns |

## Build

| Item | Value |
|------|-------|
| Script | `vivado/tcl/build_native_v1_ab_postroute_e1_65ns.tcl` |
| Vivado | 2026.1 (`C:\2026.1\Vivado\bin\vivado.bat`) |
| Top | `a7ng_native_v1_ab_core` OOC |
| Generic | `SIM_FULL=0` |
| Define | `SYNTHESIS A7LM06_SNAP_LUTRAM_BIND` |
| Part | `xc7a100tcsg324-1` |
| Clock | **65.000 ns** (~15.385 MHz) |
| Build dir | `build/native_v1_board_parallel_e1_65ns/` |
| Exit code | 0 (`route_ok=1`) |
| Bitstream | **NOT generated** (forbidden) |

## Gate metrics (post-route)

| Metric | Measured | Limit | Gate |
|--------|----------|-------|------|
| BRAM RAMB36 | 96 | ≤ 135 | **PASS** |
| BRAM RAMB18 | 0 | — | — |
| BRAM36-equiv | 96 | ≤ 135 | **PASS** |
| WNS | **−0.858 ns** | ≥ 0 ns | **FAIL** |
| TNS | **−104.814 ns** | 0 | **FAIL** |
| WHS | 0.071 ns | report | OK |
| THS | 0.000 ns | report | OK |
| Failing endpoints | 278 / 117103 | 0 | **FAIL** |
| DSP48E1 | 19 | 0 preferred | informational |

## Comparison vs 10 ns baseline (E1-AB-COFIT-PARALLEL-00)

| Metric | 10 ns run | 65 ns run | Δ |
|--------|-----------|-----------|---|
| WNS | −47.931 ns | −0.858 ns | +47.073 ns |
| TNS | −594030.500 ns | −104.814 ns | +593925.686 ns |
| Failing endpoints | 73119 | 278 | −72841 |
| BRAM RAMB36 | 96 | 96 | 0 |
| Implied critical path | ~57.9 ns | ~65.9 ns | +8.0 ns (placement variance) |

Relaxing clock from 10 ns → 65 ns closes most timing debt but **does not** reach WNS ≥ 0. Option A (clock-only co-fit at 65 ns) is **not** sufficient without pipeline.

## Utilization (post-route)

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUT | 52996 | 63400 | 83.59 |
| LUTRAM | 2144 | 19000 | 11.28 |
| FF | 49821 | 126800 | 39.28 |
| BRAM (RAMB36) | 96 | 135 | 71.11 |
| DSP48E1 | 19 | 240 | 7.92 |

## DCP SHA256

| Artifact | SHA256 |
|----------|--------|
| `ab_post_synth.dcp` | `CE2263948005C09A5F1C2481B159885BF1BADB67ABF02603672FF2A62B1BC253` |
| `ab_post_route.dcp` | `D246836323EBFBBFC120E9AC09CB3C696DF260DFA57F07A6F74D165A38BC94F8` |

## Artifacts

```text
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_post_synth.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_post_route.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_util_hier.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_util_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_timing_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_route_status.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/ab_postroute_metrics.txt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00-CLOCK65/vivado_batch.log
```

## Notes

- OOC mode: no pin LOC constraints; slack reflects logical path without top-level clock-tree placement.
- BRAM co-fit unchanged at 96 RAMB36 (≤ 135 envelope).
- Codex E1 DECIDE: falsifier supports **Option C (pipeline)** over Option A (65 ns clock alone).
