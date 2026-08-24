# CLOSEOUT — A-FAST-LM-BOARD-LANE-00 (INTERIM FAIL)

**Gate:** `native_v1_existence_board_parallel_00` Stage A  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** `XSIM_FAST_CAUSAL`  
**Verdict:** **FAIL** (stub/bridge `RLAST` mismatch blocks full `ab_core` SOA chain)

## Run summary

| Item | Result |
|------|--------|
| `tb_a7ng_native_v1_ab_fast` | **FAIL** — SOA_TIMEOUT after ID plane (256 B / 16 beats / 1 AR) |
| Bridge `rlast_error_count` | **1** at stall (`br_out=1`, `rcv=16`, `exp=16`) |
| `gv_count` / Top-K | **0** (CUE/PRIOR planes never armed) |
| Ancillary `tb_a7ng_hs22_native_ctx_fwd` | **PASS** `pred_E0=664` (bind+TinyGPT slice only; not Class A substitute) |

## Root cause (FACT)

ID-plane burst completes 16/16 beats, but `a7ng_ddr_soa_axi_bridge` records `rlast_error_count=1` and leaves `outstanding_beats_o=1`. That blocks `plane_fetch_idle`, so `pf_arm=1` for CUE plane never starts. Behavioral AXI stub variants tried (single/multi-outstanding, wf_smoke FSM, mem_model registered `RLAST`) — same failure signature.

## Falsifier status

- No TB bind/pred injection  
- `SIM_FULL=1`, backdoor `a7lm06_wmem.hex` only pre-reset  
- HS22 PASS does **not** close Class A (no live SOA→Top-8 through `a7ng_native_v1_ab_core`)

## Next unknown

Does a MIG-aligned behavioral slave (or Vivado `ddr3_model` shim) clear `rlast_error_count` for all four SOA AR bursts while keeping Class A no-PHY law?

## Artifacts

- `results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/xsim_fast.log`
- `tests/xsim/tb_a7ng_native_v1_ab_fast.sv`
- `tests/xsim/a7ng_axi_soa_mem_stub.sv`
- `tests/xsim/run_a7ng_native_v1_ab_fast.tcl`

**Date:** 2026-08-24
