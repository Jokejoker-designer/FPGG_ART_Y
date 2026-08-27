# E2R-RPATH-IDLE-CXSIM-GRANT0-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_DISPATCH.md`  
**Prior bag (control, not this UNIT):** mux dest-wait leftover after grant (`GRANT_ROSE=1`, SHA `1596C402…`)  
**Class:** C-XSIM grant=0 dest-wait occupancy  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before first dest-wait snapshot)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon dest-wait `TILE_DST=4` `GRANT=0` `RPATH_IDLE=0`. Mux XSim dest-wait idle=0 only after grant (`GRANT_ROSE=1`). B1 holds grant once risen if owner stays 1. |
| UNKNOWN | On the mux vehicle, with TB holding grant=0 from reset, does DUT-driven `dbg_tile_dst` reach 4? |
| H_CANDIDATE | dest-wait occupies with grant=0 (`dst=4`); then name AND terms at first dst=4 (`ONE`/`SET`/`NONE`). |
| H_RIVAL | Tile cannot leave `D_GO` without grant/busy; dest stays ≠4 (`FAIL_NO_DESTWAIT_GRANT0`) — silicon pair not reproduced. |
| FALSIFIER | Hierarchical force of `dst`; `assign r_path_idle=1`; product RTL; full `soc_top`+MIG only; apply C-FIX. |
| UNIT | One query, grant held 0 from reset. First dst=4 occupancy, or timeout without dst=4. Not a cycle farm. |
| CONTROL | Mux dest-wait with grant=1 (SHA `1596C402…`); silicon `GRANT=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | `tile_dst`, grant (must stay 0), owner, owner_ui, four AND terms, idle, dma go/busy. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | dest=4, grant stayed 0, exactly one AND term 1 | name only |
| `SET` | dest=4, grant stayed 0, >1 term | none |
| `NONE` | dest=4, grant stayed 0, idle=1 | none |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 while grant=0 | none |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_00_XSIM_PASS` only if dest=4, grant stayed 0, and classified.

## Legal dest-wait (declared)

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. Same mux vehicle: `a7ng_axi_read_cdc`, mux assigns including ungated `cdc_rvalid=rvalid`, WDMA AXI on the same stub R bus. **TB-only delta:** B1 grant register stays 0 (never take `r_path_idle` rise). DUT-driven `dbg_tile_dst==4` only. No hierarchical force of `dst` / `TILE_DST`. No C-FIX. No `soc_top` / MIG.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / tile `dst`
- Apply C-FIX / A2 grant/`soa_done`
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or `mig_native_wrap`
- Re-run mux leftover-after-grant as the only result
- Board / COM12 / bitstream / JTAG
- Product RTL edit
- `graph_late_materialize_00` / Phase 2
- BOARD_PASS / existence PASS
- Steal Grok R6 lock
