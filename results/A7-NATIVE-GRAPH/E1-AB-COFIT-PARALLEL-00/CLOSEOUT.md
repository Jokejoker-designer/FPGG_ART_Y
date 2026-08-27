# CLOSEOUT — E1-AB-COFIT-PARALLEL-00

**Gate:** E1-AB-COFIT-PARALLEL-00 (board lane A+B co-fit)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** POST_ROUTE_OOC  
**Verdict:** **DONE_ENG / BRAM_ONLY_PASS / OOC_TIMING_LIMIT**  
**Marker:** `E1_AB_COFIT_PARALLEL_BRAM_PASS` (timing @ 100 MHz = speed fail, not existence fail)

**Disposition (Grok DECIDE 2026-08-25, Option A):** BRAM co-fit sealed; 100 MHz WNS −47.931 ns is OOC speed limit. E2 existence at reduced graph clock pending **E1-CLOCK65** falsifier.

## Build

| Item | Value |
|------|-------|
| Script | `vivado/tcl/build_native_v1_ab_postroute_e1.tcl` |
| Vivado | 2026.1 (`C:\2026.1\Vivado\bin\vivado.bat`) |
| Top | `a7ng_native_v1_ab_core` OOC |
| Generic | `SIM_FULL=0` |
| Define | `SYNTHESIS A7LM06_SNAP_LUTRAM_BIND` |
| Part | `xc7a100tcsg324-1` |
| Clock | 100 MHz (10 ns) |
| Build dir | `build/native_v1_board_parallel_e1/` |
| Exit code | 0 (`route_ok=1`) |
| Bitstream | **NOT generated** (forbidden) |

## Gate metrics (post-route)

| Metric | Measured | Limit | Gate |
|--------|----------|-------|------|
| BRAM RAMB36 | 96 | ≤ 135 | **PASS** |
| BRAM RAMB18 | 0 | — | — |
| BRAM36-equiv | 96 | ≤ 135 | **PASS** |
| WNS | **-47.931 ns** | ≥ 0 ns | **FAIL** |
| TNS | **-594030.500 ns** | 0 | **FAIL** |
| WHS | 0.070 ns | report | OK |
| THS | 0.000 ns | report | OK |
| Failed nets | 0 | 0 | **PASS** |
| Fully routed nets | 94506 / 94506 | complete | **PASS** |

## Utilization (post-route, hierarchical top)

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUT | 52996 | 63400 | 83.59 |
| LUTRAM | 2144 | 19000 | 11.28 |
| FF | 49828 | 126800 | 39.30 |
| BRAM (RAMB36) | 96 | 135 | 71.11 |
| DSP48E1 | 19 | 240 | 7.92 |

**Control reference:** LM06-SNAPSHOT-LUTRAM-01 snap variant reported 130 BRAM; this A+B hierarchy uses 96 BRAM (39 below envelope).

## DCP SHA256

| Artifact | SHA256 |
|----------|--------|
| `ab_post_synth.dcp` | `4055C5FA6529F9BA9E2BA8A8BD939CB3CBA483A5501CF38FE4D1BB83F2E60A24` |
| `ab_post_route.dcp` | `8F5A554A94C938E819394744D8FF098E77F428ACFA799F7077B8C91225C03B7E` |

## Falsifier outcome

H_CANDIDATE **partially confirmed:** BRAM fits (96 ≤ 135) and route completes with 0 failed nets.  
H_RIVAL **confirmed on timing:** WNS = -47.931 ns, TNS = -594030.500 ns (73119 failing endpoints). OOC post-route timing is not met at 100 MHz.

## Artifacts

```text
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_post_synth.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_post_route.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_util_hier.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_util_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_timing_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_route_status.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_postroute_metrics.txt
```

## Notes

- OOC mode: no pin LOC constraints; WNS/TNS reflect logical path slack without top-level clock-tree placement.
- BRAM co-fit passes; timing is the blocking unknown for board-lane integration at 100 MHz.
- DSP count = 19 (informational; not in preregister pass/fail table).
