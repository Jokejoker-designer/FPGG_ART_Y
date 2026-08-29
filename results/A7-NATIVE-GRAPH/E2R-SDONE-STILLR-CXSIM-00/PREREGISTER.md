# E2R-SDONE-STILLR-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_STILLR_CXSIM_DISPATCH.md`  
**Control bags:** SDONE-CXSIM ROSE (`xsim.log` SHA `DF55ACF4…`); ATOMIC-SGO silicon dest=4 `dma_st=5(R)` leftover SET; sequential UART `SDONE=0`  
**Class:** C-XSIM mux vehicle, still-in-R at first dest=4, complete **after** snap  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.

Frozen before UNIT run. XSim ≠ board. Sequential UART `SDONE=0` is not answered by this bag.

## Scientific frame (frozen before UNIT run)

| Field | Value |
|-------|-------|
| OBSERVATION | ROSE bag finished first burst before dest=4 (`snap w_st=0`, sticky already 1). Silicon ATOMIC-SGO dest=4 still-in-R (`dma_st=5`). Occupancies differ. Sequential `SDONE=0` unanswered. |
| UNKNOWN | At first dest=4 ∧ grant=1 ∧ leftover SET, if the responder is still busy/in-R (then completes later), is `dbg_s_done_sticky` 0 or 1? |
| H_CANDIDATE | `SNAP_DONE0` — sticky=0 at dest=4 while in-R. Silicon `SDONE=0` can be same-cycle still-in-R. |
| H_RIVAL | `SNAP_DONE1` — sticky=1 at dest=4 even while current burst in-R (prior done). |
| FALSIFIER | Complete before dest=4 (ROSE bag); hold busy forever (MUX); C-FIX; A2; LiteScope; `soc_top`+MIG; force dest. |
| UNIT | One query. First dest=4 snap. After-complete sticky is a secondary metric, not a second unknown. |
| CONTROL | SDONE-CXSIM ROSE SHA `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520`; ATOMIC-SGO `dma_st=5`; sequential `SDONE=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. `s_dma_idle=1'b0` kept as CONTROL. |
| METRICS | dest, leftover, in-R/busy at snap, `s_go` ever, sticky at dest=4, sticky after later complete. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX | Marker |
|-------|---------|-------|--------|
| `SNAP_DONE0` | dest=4 + in-R/busy + sticky=0 | none | `E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS` |
| `SNAP_DONE1` | dest=4 + in-R/busy + sticky=1 | none | `E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS` |
| `FAIL_NOT_IN_R` | dest=4 but not in-R (vehicle miss) | none | no PASS marker |
| `FAIL_NO_DESTWAIT` | never dest=4 | none | no PASS marker |

in-R/busy at snap := (`snap_wst==W_R`) ∧ (`s_dma_busy` at snap). Not a cycle farm.

## Vehicle (TB-only vs ROSE CONTROL)

Copy `tb_e2r_sdone_cxsim_00.sv` (ROSE completable responder). Keep mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest=4 only. No `soc_top`. No MIG.

**One TB change:** do **not** pulse `s_done` / clear busy until **after** first dest=4 is latched (keep in-R through that snap), then complete the burst. Do not complete before dest=4. Do not hold forever after dest=4. Do not retie `s_dma_idle`. Do not force dest. Do not apply C-FIX.

`destwait_seen` (core) is 2-FF synced to `ui_clk` as `dest4_seen_ui`. After 8 shared-stub R beats, stay in `W_R` with `busy=1` `done=0` and `r_left=0` (no extra R consume) until `dest4_seen_ui`, then `W_HOLD` pulse.

## Forbidden

- Complete the burst before first dest=4 (ROSE / FALSIFIER)
- Hold `busy=1` `done=0` forever after dest=4 (MUX / FALSIFIER)
- `assign r_path_idle=1`
- Force `TILE_DST` / dest
- C-FIX / A2 / B1 grant change
- LiteScope / ILA
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Retie `s_dma_idle` (keep CONTROL `1'b0`)
- Product RTL edit
- Board / COM / bitstream / JTAG
- BOARD_PASS / existence PASS
- Sell silicon `SDONE=0` as answered

## Analysis plan (before run)

- Snapshot at first DUT-driven `TILE_DST==4` on `core_clk`.
- `dbg_s_done_sticky` lives on `s_clk`; 2-FF sync to `core_clk` for the dest=4 row.
- After dest-wait, settle 128 `core_clk` cycles, then watch up to 8192 more `core_clk` cycles for later complete (secondary metric).
- One query = one UNIT. No cycle-farm inference.
- `C_FIX=NONE`. `BOARD_PASS` not claimed. XSim ≠ board.
