# E2R-SDONE-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_CXSIM_DISPATCH.md`  
**Control bags:** `E2R-SGO-CXSIM-MUX-00` (hold `busy=1` `done=0` after 8 R); `E2R-SGO-LATCH-CXSIM-00` (same hold); ATOMIC-SGO silicon dest=4 grant=1 leftover SET sticky=1 own_ui=1 dma_st=5(R); sequential UART `SDONE=0` `W_STALL` `PHASE=01`  
**Class:** C-XSIM mux vehicle, completable-responder `s_done` unknown  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before UNIT run)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon SGO_HIT and DMA in R at dest=4. UART `SDONE=0`. Old MUX bag forced hold-busy after 8 shared-stub R — that vehicle cannot answer done. |
| UNKNOWN | On dest=4 ∧ grant=1 ∧ leftover SET ∧ `s_go` fired, if the WDMA responder completes (deassert busy, pulse done after legal 8 R), does `s_done` / `dbg_s_done_sticky` rise? |
| H_CANDIDATE | `SDONE_NEVER` — leftover SET keeps DMA in R; done never. |
| H_RIVAL | `SDONE_ROSE` — done rises after complete beats. Silicon `SDONE=0` is stub≠board / still-in-R. |
| FALSIFIER | Hold `busy=1` `done=0` after 8 R (old MUX); C-FIX; A2; LiteScope; `soc_top`+MIG; force dest. |
| UNIT | One query. First dest=4 snapshot + whether done ever in that query. Not a cycle farm. |
| CONTROL | MUX hold-busy (done forced 0); ATOMIC-SGO dma_st=5; sequential `SDONE=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. `s_dma_idle=1'b0` kept as CONTROL (completable responder clears `s_busy` / pulses `s_done` only; idle pin not retied). |
| METRICS | dest, grant, leftover terms, `s_go` ever, `s_done` ever, `dbg_s_done_sticky`, `dbg_m_done_sticky`, dma FSM (`w_st`), busy (`s_dma_busy` / `wdma_busy`) at dest=4 and at end. |

## Verdict classes (preregistered)

| Class | Meaning | Marker |
|-------|---------|--------|
| `SDONE_ROSE` | dest=4 reached; `s_done` ever or `dbg_s_done_sticky=1` in that query | `E2R_SDONE_CXSIM_00_XSIM_PASS` |
| `SDONE_NEVER` | dest=4 reached; `s_go` fired; done/sticky never | `E2R_SDONE_CXSIM_00_XSIM_PASS` |
| `FAIL_NO_DESTWAIT` | never dest=4 | no PASS marker |

Residual (declared, not a PASS class): dest=4 and `s_go` never and done never → `SDONE_NO_SGO`. Do **not** emit the PASS marker.

## Vehicle (TB-only vs MUX / LATCH CONTROL)

Copy `tb_e2r_sgo_cxsim_mux_00.sv` (LATCH is the same hold-busy responder plus a UART latch replica, unused here). Keep mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest=4 only. No `soc_top`. No MIG.

**One TB change:** after 8 shared-stub R beats, pulse `s_done` and clear `s_busy` (completable responder). Do not hold `busy=1` `done=0`. Do not retie `s_dma_idle`. Do not force dest. Do not apply C-FIX.

## Forbidden

- Hold `busy=1` `done=0` after 8 R (FALSIFIER)
- `assign r_path_idle=1`
- Force `TILE_DST` / dest
- C-FIX / A2 / B1 grant change
- LiteScope / ILA
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Retie `s_dma_idle` (keep CONTROL `1'b0`; document if idle must follow done — it does not for this unknown)
- Product RTL edit
- Board / COM / bitstream / JTAG
- BOARD_PASS / existence PASS

## Analysis plan (before run)

- Snapshot at first DUT-driven `TILE_DST==4` on `core_clk`.
- `dbg_s_done_sticky` lives on `s_clk`; 2-FF sync to `core_clk` for the dest=4 row. Also log the raw pulse-ever on `s_clk`.
- After dest-wait, settle 128 `core_clk` cycles (CONTROL-matched leftover window), then watch up to 8192 more `core_clk` cycles if done has not yet been seen (query-ever window).
- One query = one UNIT. No cycle-farm inference.
- `C_FIX=NONE`. `BOARD_PASS` not claimed. XSim ≠ board.
