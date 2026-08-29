# E2R-SGO-CXSIM-MUX-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-SGO-CXSIM-MUX-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX. Do not add LiteScope/ILA.**

F1x ATOM (board): dest=4 grant=1 idle=0 fifo_ne+c_rvalid. Sequential UART `SGO=0` is not same-cycle.  
MUX bag ([68c480da](68c480da-8863-496b-b5cc-4b6c9ccf9a79)): dest=4 grant=1 leftover SET. Printed `go=` was **`wdma_go` (m_go)**, not `s_go`. `dbg_s_go_sticky` was unconnected.

## Scientific frame

- **OBSERVATION:** ATOM grant=1 at dest=4. UART still prints `SGO=0` `DMA_ST=0`. MUX dest-wait `wdma_go=0` after the start pulse.
- **UNKNOWN:** on the MUX occupancy that matches ATOM (first dest=4 ∧ grant=1 ∧ leftover SET), does `dbg_s_go_sticky` ever rise?
- **H_CANDIDATE:** sticky=0 for the whole query (`SGO_NEVER`) — silicon `SGO=0` can be a true miss.
- **H_RIVAL:** sticky=1 at or before first dest=4 (`SGO_ROSE`) — sequential UART `SGO=0` is print-time, like GRANT skew.
- **FALSIFIER:** force dest; C-FIX; A2; LiteScope; `soc_top`+MIG; change B1; retie `s_dma_idle` (keep CONTROL `1'b0` as MUX bag).
- **UNIT:** one query on the MUX vehicle. First dest=4 occupancy is the snapshot; sticky is allowed to have risen earlier in the same query.
- **CONTROL:** MUX dest=4 grant=1 leftover SET; F1x ATOM same leftover pair grant=1; silicon sequential `SGO=0`.
- **METRICS:** dest, grant, idle, fifo, c_rvalid, `s_go` pulse-ever, `dbg_s_go_sticky` at first dest=4 and at end, `dbg_m_go_sticky`, `dbg_cmd_st`, `dbg_sbusy_pend`, `dbg_cmd_rd_sticky`, dma FSM if present.

## Vehicle

Copy `E2R-RPATH-IDLE-CXSIM-MUX-00/tb_e2r_rpath_idle_cxsim_mux_00.sv` **TB-only**.  
Keep mux + B1 + shared stub + `s_dma_idle=1'b0` + hold busy after 8 R.  
Wire `dbg_s_go_sticky` / `dbg_m_go_sticky` / cmd probes (MUX left them open).  
`SIM_FULL=0`. DUT-driven dest=4 only. No `soc_top`. No MIG.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `SGO_ROSE` | sticky=1 at first dest=4 or earlier in that query | none |
| `SGO_NEVER` | dest=4 reached, sticky=0 at dest=4 and at end | none |
| `FAIL_NO_DESTWAIT` | never dest=4 | none |

Marker `E2R_SGO_CXSIM_MUX_00_XSIM_PASS` only if `SGO_ROSE` or `SGO_NEVER`.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`. Existence remains `pred=664`.
