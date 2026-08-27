# E2R C-XSIM-GRANT0-RINJ — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-GRANT0-RINJ-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

GRANT0 (SHA `E2B2BA9A…`): grant=0 → dest `D_DRAIN=3`, WDMA `W_WAITOWN`, no R, never dest=4.  
Silicon UART last snapshot (same-cycle latch): `TILE_DST=4` `GRANT=0` `OWNER=1`.

## Scientific frame

- **OBSERVATION:** GRANT0 dest starved in `D_DRAIN` without R. Silicon claims dest=4 with grant=0.
- **UNKNOWN:** with TB grant held 0, after DUT dest reaches 3, do 8 TB-injected WDMA R beats (`dma_r_valid` toward the tile / CDC slave R) make DUT-driven `dbg_tile_dst==4`?
- **H_CANDIDATE:** yes — leftover R can complete drain without grant (silicon pair possible on this vehicle). Then classify four idle AND terms at first dest=4.
- **H_RIVAL:** dest stays 3 (`FAIL_NO_DESTWAIT_GRANT0`) — leftover R is not enough; silicon pair still unreproduced.
- **FALSIFIER:** force `dst`; raise grant; product RTL; C-FIX; board; full MIG-only as the sole plan.
- **UNIT:** one query; grant=0 from reset; inject exactly 8 R beats after first dest==3.
- **CONTROL:** GRANT0 no-inject dest=3 (SHA `E2B2BA9A…`); mux dest=4 only after grant.
- **METRICS:** dest before/after inject, grant (must stay 0), owner, four AND terms, idle at dest=4 if reached.

## Vehicle

Copy GRANT0 TB. After first `dbg_tile_dst==3`, inject 8 combinational-legal R beats on the WDMA R path **without** setting grant. Do not force dest. `SIM_FULL=0`.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE`/`SET`/`NONE` | dest=4, grant=0, AND terms classified | name only if ONE |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 after 8 R | no C-FIX |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_RINJ_00_XSIM_PASS` only if dest=4, grant stayed 0, classified.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
