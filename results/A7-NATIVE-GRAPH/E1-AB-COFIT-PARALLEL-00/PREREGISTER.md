# PREREGISTER — E1-AB-COFIT-PARALLEL-00

**Status:** SEALED BEFORE RUN  
**Owner:** Cursor board lane (`native_v1_existence_board_parallel_00`)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** `POST_ROUTE_OOC` / `PASS_NARROW`  
**Bitstream / board program:** **FORBIDDEN** (DCP + reports only)

## Prerequisite

- Stage A **PASS** — `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664`  
- VERIFY trio **PASS** — `AUDIT_EVIDENCE.md`, `AUDIT_XSIM.md`, `AUDIT_HLB.md`

## ONE UNKNOWN

Does the **actual** board-lane A+B hierarchy (`a7ng_native_v1_ab_core`, `SIM_FULL=0`, `A7LM06_SNAP_LUTRAM_BIND`) fit `xc7a100tcsg324-1` with BRAM≤135, WNS≥0, TNS=0, complete route?

## CONTROL

| Item | Value |
|------|--------|
| Top | `a7ng_native_v1_ab_core` OOC |
| Generic | `SIM_FULL=0` |
| Define | `SYNTHESIS A7LM06_SNAP_LUTRAM_BIND` |
| Part | `xc7a100tcsg324-1` |
| Clock | 100 MHz (10 ns) |
| Build dir | `build/native_v1_board_parallel_e1/` |
| Out dir | `results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/` |
| RTL | includes field-split `a7ng_cue_soa_wavefront.sv` from Stage A fix |

## METRICS (pass/fail)

| Metric | Limit |
|--------|-------|
| BRAM (RAMB36 equiv) | ≤ 135 |
| WNS | ≥ 0 |
| TNS | 0 |
| Route | complete, 0 failed nets |

## FALSIFIER

- Proxy additive BRAM guess without hierarchical report  
- `write_bitstream` in this gate  
- Output to R6 `NATIVE-V1-AB-INTEGRATE-ACCEPT-00/` paths  
- `SIM_FULL=1` in synthesis  

## Required artifacts

```text
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_post_synth.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_post_route.dcp
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_util_hier.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_timing_route.rpt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ab_postroute_metrics.txt
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/CLOSEOUT.md
```

## PASS marker

`E1_AB_COFIT_PARALLEL_POSTROUTE_PASS` with BRAM/WNS/TNS in CLOSEOUT

**Seal SHA:** compute after file write → `PREREGISTER_SEAL_SHA256.txt`
