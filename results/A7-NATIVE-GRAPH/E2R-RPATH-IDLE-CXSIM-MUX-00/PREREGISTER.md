# E2R-RPATH-IDLE-CXSIM-MUX-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_MUX_DISPATCH.md`  
**Prior bag (control, not re-run as the only result):** dest-wait separate-WDMA `NONE` (SHA `DAD0E6DE…`)  
**Class:** C-XSIM mux half of leftover unknown  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before first dest-wait snapshot)

| Field | Value |
|-------|-------|
| OBSERVATION | Separate-WDMA dest-wait idle=1. Silicon dest-wait `RPATH_IDLE=0` `GRANT=0`. SoC `cdc_rvalid=rvalid` ungated. |
| UNKNOWN | At first legal `TILE_DST==4` through shared stub + AXI-read CDC + B1 + ungated `cdc_rvalid`, which of `r_drain_hold` / `fifo_cnt` / `m_axi_rvalid` (`c_rvalid`) / `tr_cnt` is 1. |
| H_CANDIDATE | Shared-bus leftover or WDMA R seen by ungated `cdc_rvalid` holds `c_rvalid` → idle=0. |
| H_RIVAL | Dest-wait still idle=1 (`NONE`) — leftover is true MIG-only. |
| FALSIFIER | Force `dst`; full `soc_top`/MIG only; apply C-FIX; `FAIL_NO_DESTWAIT`; `SET` if >1 term. |
| UNIT | First dest-wait occupancy after one query. Not a cycle farm. |
| CONTROL | Dest-wait separate-WDMA idle=1 (SHA `DAD0E6DE…`); silicon `GRANT=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | `tile_dst`, four AND terms, `r_path_idle`, `wdma_owner`, `wdma_owner_grant`, `wdma_owner_ui`, `cdc_rvalid`, stub `rvalid`, `grant_rose_before_destwait`. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | exactly one named AND term is 1 at first dest-wait | NAME ONLY — do not apply |
| `SET` | two or more terms 1 | none |
| `NONE` | dest-wait reached and all four clear / idle=1 | none |
| `FAIL_NO_DESTWAIT` | never `TILE_DST==4` | none |

## Legal dest-wait (declared)

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. TB-only: `a7ng_axi_read_cdc`, B1 grant FF (SoC law copy), mux assigns including ungated `cdc_rvalid=rvalid`, WDMA AXI on the **same** stub R bus (via `a7ng_wdma_cdc` + TB responder hold `busy=1` `done=0` after 8 R beats). DUT-driven `dbg_tile_dst==4` only. No hierarchical force of `dst` / `TILE_DST`. No C-FIX. No `soc_top` / MIG.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / tile `dst`
- Apply C-FIX / A2 grant/`soa_done`
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or `mig_native_wrap`
- Re-run dest-wait/INT/CDC bags as the only result
- Board / COM12 / bitstream / JTAG
- Product RTL edit
- `graph_late_materialize_00` / Phase 2
- BOARD_PASS / existence PASS
- Steal Grok R6 lock
