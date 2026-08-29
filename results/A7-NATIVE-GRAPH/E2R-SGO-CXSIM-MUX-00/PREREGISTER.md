# E2R-SGO-CXSIM-MUX-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SGO_CXSIM_MUX_DISPATCH.md`  
**Control bag:** `E2R-RPATH-IDLE-CXSIM-MUX-00` (dest=4 grant=1 leftover SET; printed `go=` was `wdma_go` / `m_go`; `dbg_s_go_sticky` unconnected)  
**Class:** C-XSIM mux vehicle, SGO sticky unknown  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before UNIT run)

| Field | Value |
|-------|-------|
| OBSERVATION | F1x ATOM dest=4 grant=1 idle=0 fifo_ne+c_rvalid. Sequential UART `SGO=0` is not same-cycle. MUX bag printed `go=` as `wdma_go` (`m_go`), not `s_go`. `dbg_s_go_sticky` was unconnected. |
| UNKNOWN | On first dest=4 ∧ grant=1 ∧ leftover SET (ATOM occupancy), does `dbg_s_go_sticky` rise? |
| H_CANDIDATE | sticky=0 whole query (`SGO_NEVER`) — silicon `SGO=0` can be a true miss. |
| H_RIVAL | sticky=1 at or before first dest=4 (`SGO_ROSE`) — UART `SGO=0` is print-time like GRANT skew. |
| FALSIFIER | Force dest; C-FIX; A2; LiteScope; `soc_top`+MIG; change B1; retie `s_dma_idle` (keep CONTROL `1'b0`). |
| UNIT | One query. First dest=4 is the snapshot; sticky may have risen earlier in the same query. |
| CONTROL | MUX dest=4 grant=1 leftover SET; F1x ATOM same leftover pair grant=1; silicon sequential `SGO=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. `s_dma_idle=1'b0`. |
| METRICS | dest, grant, idle, fifo, c_rvalid, `s_go` pulse-ever, `dbg_s_go_sticky` at first dest=4 and at end, `dbg_m_go_sticky`, `dbg_cmd_st`, `dbg_sbusy_pend`, `dbg_cmd_rd_sticky`. |

## Verdict classes (preregistered)

| Class | Meaning | Marker |
|-------|---------|--------|
| `SGO_ROSE` | dest=4 reached; `dbg_s_go_sticky=1` at first dest=4 (or earlier in that query) | `E2R_SGO_CXSIM_MUX_00_XSIM_PASS` |
| `SGO_NEVER` | dest=4 reached; sticky=0 at dest=4 **and** at end | `E2R_SGO_CXSIM_MUX_00_XSIM_PASS` |
| `FAIL_NO_DESTWAIT` | never dest=4 | no PASS marker |

Residual (declared, not a 4th PASS class): sticky=0 at dest=4 and 1 at end is not `SGO_ROSE` and not `SGO_NEVER`. Print `CLASS=SGO_LATE` and do **not** emit the PASS marker.

## Vehicle (TB-only vs MUX CONTROL)

Copy MUX TB. Keep mux + B1 + shared stub + `s_dma_idle=1'b0` + hold busy after 8 R. `SIM_FULL=0`. DUT-driven dest=4 only.

**One TB change:** wire `dbg_s_go_sticky` / `dbg_m_go_sticky` / cmd probes that MUX left open. Do not retie `s_dma_idle`. Do not force dest. Do not apply C-FIX.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / dest
- C-FIX / A2 / B1 grant change
- LiteScope / ILA
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Retie `s_dma_idle` (keep `1'b0`)
- Steal Grok R6 / Phase 2 / `graph_late_materialize_00`
- Product RTL edit
- Board / COM12 / bitstream / JTAG
- BOARD_PASS / existence PASS

## Analysis plan (before run)

- Snapshot at first DUT-driven `TILE_DST==4` on `core_clk`.
- `dbg_s_go_sticky` lives on `s_clk`; 2-FF sync to `core_clk` for the dest=4 row. Also log the raw port.
- After dest-wait, settle 128 `core_clk` cycles with busy held (dest stays 4) for END metrics.
- One query = one UNIT. No cycle-farm inference.
- `C_FIX=NONE`. `BOARD_PASS` not claimed. XSim ≠ board.
