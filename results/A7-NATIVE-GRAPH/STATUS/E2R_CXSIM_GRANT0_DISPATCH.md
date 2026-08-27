# E2R C-XSIM-GRANT0 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-GRANT0-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

Silicon pair is `TILE_DST=4` **and** `GRANT=0`. Mux bag reproduced leftover only **after** grant (`GRANT_ROSE=1`). That is the wrong occupancy.

## Scientific frame

- **OBSERVATION:** Silicon dest-wait `TILE_DST=4` `GRANT=0` `RPATH_IDLE=0`. Mux XSim dest-wait idle=0 only after grant rose. B1: grant rises only when `owner && r_path_idle`; if it ever rose while owner=1 it would hold.
- **UNKNOWN:** on the mux vehicle, with TB **holding grant=0** (silicon control), does DUT-driven `dbg_tile_dst` reach `4`?
- **H_CANDIDATE:** dest-wait can occupy with grant=0; then name AND terms at first dst=4 (`ONE`/`SET`/`NONE`).
- **H_RIVAL:** tile cannot leave `D_GO` without grant/busy; dest stays ≠4 (`FAIL_NO_DESTWAIT_GRANT0`) — silicon `TILE_DST=4∧GRANT=0` is not reproduced (UART/probe contradiction or MIG-only path).
- **FALSIFIER:** hierarchical force of `dst`; `assign r_path_idle=1`; product RTL; full `soc_top`+MIG only; apply C-FIX.
- **UNIT:** one query, grant held 0 from reset. First dst=4 occupancy, or timeout without dst=4.
- **CONTROL:** mux bag dest-wait with grant=1 (SHA `1596C402…`); silicon GRANT=0.
- **METRICS:** tile_dst, grant (must stay 0), owner, owner_ui, four AND terms, idle, dma_busy/go, SGO if probed.

## Vehicle

Copy `tb_e2r_rpath_idle_cxsim_mux_00.sv`. **TB-only** change: B1 grant register stays 0 (tie / never take the `r_path_idle` rise). Do not force tile `dst`. Same shared stub + CDC + ungated `cdc_rvalid`. `SIM_FULL=0`.

## Verdict classes

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | dest=4, grant=0, exactly one AND term 1 | name only |
| `SET` | dest=4, grant=0, >1 term | no C-FIX |
| `NONE` | dest=4, grant=0, idle=1 | no C-FIX |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 while grant=0 | no C-FIX |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_00_XSIM_PASS` only if dest=4 and grant stayed 0 and classified.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
