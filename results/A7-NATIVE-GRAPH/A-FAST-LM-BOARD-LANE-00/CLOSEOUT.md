# CLOSEOUT — A-FAST-LM-BOARD-LANE-00

**Gate:** `native_v1_existence_board_parallel_00` Stage A  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** `XSIM_FAST_CAUSAL`  
**Verdict:** **PASS**

## Run summary

| Item | Result |
|------|--------|
| `tb_a7ng_native_v1_ab_fast` | **PASS** `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` |
| SOA transport | 832 B / 52 beats / 4 AR / 4 waves / `data_mismatch=0` |
| Global Top-8 | `9,11,25,27,41,43,57,59` @ 165 |
| CAPTURE | `ctx_pack=3b392b291b190b09` |
| LM forward | `pred=664`, `start_fwd_beats=1`, `dual_ticks=0` |

## Root cause closed

`rec0` fill bank used `(* ram_style="distributed" *)` 128-bit words; XSim left the 32-bit ID field one record behind on even waves (`mm=31`, Top-8 off-by-one). Fix: field-split wave banks in `a7ng_cue_soa_wavefront.sv`.

## Law

- Class A: live SOA→Top-8→bind→TinyGPT through `a7ng_native_v1_ab_core` with `SIM_FULL=1`, AXI stub, backdoor `wmem.hex`.
- HS22 ancillary PASS does not substitute Class A (now superseded by this closeout).

## Next

- Stage E1 co-fit (`E1-AB-COFIT-PARALLEL-00`) when authorized.
- Stage E2 board requires Codex `ALLOW_PROGRAM` / `com12_authorized_gate`.
- Cherry-pick `a7ng_cue_soa_wavefront.sv` field-split fix to R6 main tree (Grok-owned).

**Date:** 2026-08-24
