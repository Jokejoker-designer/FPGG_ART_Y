# E2R-RPATH-IDLE-CXSIM-DESTWAIT-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_DESTWAIT_DISPATCH.md`  
**Prior bags (sealed, not re-run as the only result):** isolated / INT / CDC complete-query `NONE`  
**Class:** C-XSIM dest-wait half of the same leftover unknown  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before first dest-wait snapshot)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon dest-wait `TILE_DST=4` `RPATH_IDLE=0` `GRANT=0` (BIT `6023D9A3…`). Complete-query XSim idle=1 after SOA drain. |
| UNKNOWN | Which of `r_drain_hold`, `fifo_cnt!=0`, `m_axi_rvalid`, `tr_cnt!=0` is 1 at first legal `dbg_tile_dst_o==3'd4`. |
| H_CANDIDATE | `m_axi_rvalid` leftover holds idle=0 at dest-wait. |
| H_RIVAL | `fifo_cnt`/`tr_cnt` leftover; or dest-wait also idle=1 (`NONE` — leftover not on this stub path). |
| FALSIFIER | Never reach dest-wait (`FAIL_NO_DESTWAIT`); hierarchical force of `TILE_DST`/`dst`; `assign r_path_idle=1`; more than one term independently 1 (`SET`). |
| UNIT | First dest-wait occupancy after one query start. Not a cycle farm. |
| CONTROL | C-XSIM isolated/INT/CDC idle=1 after complete SOA. Silicon dest-wait idle=0. `SIM_FULL=0` (silicon SoC). WDMA responder holds `busy=1` `done=0` after 8 legal R beats. |
| METRICS | `tile_dst`, `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt`, `r_path_idle`, `wdma_owner`, `wdma_owner_grant` at first dest-wait cycle. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | exactly one named AND term is 1 at first dest-wait | NAME ONLY — do not apply |
| `SET` | two or more terms 1 | none |
| `NONE` | dest-wait reached and all four clear / idle=1 | none |
| `FAIL_NO_DESTWAIT` | never `TILE_DST==4` | none |

## Legal dest-wait (declared)

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. Tile law: D_IDLE→D_GO needs `req && !dma_busy`; D_GO→D_DRAIN needs `dma_busy`; D_DRAIN→D_WAITDONE needs 8 `dma_r_valid` beats; leaving `wdma_busy=0` sticks at `D_GO=1`.

TB WDMA responder only: on `wdma_go` assert busy, return 8 read beats, then hold `busy=1` `done=0`. No hierarchical force of `dst` / `TILE_DST`. No C-FIX. No B1 grant/`soa_done` product edit.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / tile `dst`
- Apply C-FIX / A2 grant/`soa_done`
- Re-run sealed complete-query bags as the only result
- Board / COM12 / bitstream / JTAG
- Product RTL edit
- `graph_late_materialize_00` / Phase 2
- BOARD_PASS / existence PASS
