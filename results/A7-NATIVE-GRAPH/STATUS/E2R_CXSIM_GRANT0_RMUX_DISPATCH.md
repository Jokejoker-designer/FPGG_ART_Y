# E2R C-XSIM-GRANT0-RMUX — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-GRANT0-RMUX-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

RINJ (0adb1b5b, SHA `3F169C1C…`): grant=0 + 8 CDC-slave `dma_r_valid` → dest=4, idle=1, WDMA stayed `W_WAITOWN`. Inject **bypassed** shared mux. Silicon UART same-cycle latch: `TILE_DST=4` `GRANT=0` `RPATH_IDLE=0`.

## Scientific frame

- **OBSERVATION:** leftover **tile-side** R can occupy dest=4 with grant=0 and idle=1. Silicon leftover is idle=0. MUX leftover (fifo+`c_rvalid`) existed only **after grant**.
- **UNKNOWN:** with grant held 0 and `wdma_owner_ui=0`, after DUT dest reaches 3, do 8 leftover beats on the **shared stub R** (mux `rvalid` / ungated `cdc_rvalid=rvalid`) make DUT-driven `dbg_tile_dst==4`? If dest=4, classify four idle AND terms.
- **H_CANDIDATE:** mux leftover R without grant reaches dest=4 and holds idle=0 (silicon triple occupiable; then `ONE`/`SET`/`NONE`).
- **H_RIVAL:** dest stays 3 (`FAIL_NO_DESTWAIT_GRANT0`) — mux leftover does not complete drain without grant; dest=4 on silicon is tile-side leftover only.
- **FALSIFIER:** force `dst`; raise grant; inject on CDC-slave `dma_r_valid` (that is RINJ, already sealed); product RTL; C-FIX; board.
- **UNIT:** one query; grant=0 from reset; after first dest==3 inject exactly 8 leftover beats on shared stub R. Do **not** drive CDC-slave `dma_r_valid` as the inject.
- **CONTROL:** RINJ dest=4 idle=1 via CDC-slave inject (SHA `3F169C1C…`); GRANT0 no-inject dest=3; mux dest=4 only after grant.
- **METRICS:** dest before/after inject, grant stayed 0, `own_ui`, four AND terms, idle if dest=4, `R_INJECTED`, stub/`cdc_rvalid`.

## Vehicle

Copy RINJ/GRANT0 TB (`tb_e2r_rpath_idle_cxsim_grant0_rinj_00.sv`). Same mux vehicle. Grant register stays 0. After first `dbg_tile_dst==3`, inject 8 combinational-legal leftover beats on the **shared stub R into the mux** (the path that becomes ungated `cdc_rvalid`). Do **not** mux-bypass via CDC-slave `dma_r_valid`. Do not force dest. `SIM_FULL=0`.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE`/`SET`/`NONE` | dest=4, grant stayed 0, AND terms classified | name only if ONE |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 after 8 mux leftover R | no C-FIX |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_RMUX_00_XSIM_PASS` only if dest=4, grant stayed 0, classified.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
