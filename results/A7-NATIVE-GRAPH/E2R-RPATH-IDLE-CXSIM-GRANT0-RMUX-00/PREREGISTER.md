# E2R-RPATH-IDLE-CXSIM-GRANT0-RMUX-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_RMUX_DISPATCH.md`  
**Prior bag (control, not this UNIT):** RINJ dest=4 idle=1 via CDC-slave `dma_r_valid` (SHA `3F169C1C…`); GRANT0 no-inject dest=3; mux dest=4 only after grant.  
**Class:** C-XSIM grant=0 leftover-R on shared mux (not CDC-slave)  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before first dest=4 snapshot)

| Field | Value |
|-------|-------|
| OBSERVATION | Tile-side leftover R can occupy dest=4 with grant=0 and idle=1 (RINJ SHA `3F169C1C…`). Silicon leftover is idle=0 (`TILE_DST=4` `GRANT=0` `RPATH_IDLE=0`). Mux leftover (fifo + `c_rvalid`) existed only after grant. |
| UNKNOWN | With grant held 0 and `wdma_owner_ui=0`, after first `dbg_tile_dst==3`, do 8 leftover beats on the shared stub R (mux `rvalid` / ungated `cdc_rvalid=rvalid`) make DUT-driven `dbg_tile_dst==4`? If dest=4, classify four idle AND terms. |
| H_CANDIDATE | Mux leftover R without grant reaches dest=4 and holds idle=0 (silicon triple occupiable; then `ONE`/`SET`/`NONE`). |
| H_RIVAL | dest stays 3 (`FAIL_NO_DESTWAIT_GRANT0`) — mux leftover does not complete drain without grant; dest=4 on silicon is tile-side leftover only. |
| FALSIFIER | Force `dst` / `TILE_DST`; raise grant; inject on CDC-slave `dma_r_valid` (RINJ, sealed); product RTL; C-FIX; A2; board; `soc_top`+MIG. |
| UNIT | One query; grant=0 from reset; after first dest==3 inject exactly 8 leftover beats on shared stub R into the mux. Not a cycle farm. |
| CONTROL | RINJ dest=4 idle=1 via CDC-slave (SHA `3F169C1C…`); GRANT0 no-inject dest=3; mux dest=4 only after grant. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | dest before/after inject, grant (must stay 0), `own_ui`, four AND terms, idle if dest=4, `R_INJECTED`, stub/`cdc_rvalid`. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | dest=4, grant stayed 0, exactly one AND term 1 | name only |
| `SET` | dest=4, grant stayed 0, >1 term | none |
| `NONE` | dest=4, grant stayed 0, idle=1 / n_hot=0 | none |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 after 8 mux leftover R | none |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_RMUX_00_XSIM_PASS` only if dest=4, grant stayed 0, and classified.

## Legal dest-wait (declared)

Copy of RINJ/GRANT0 TB. `a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. Same mux vehicle. **TB-only delta:** after first `dbg_tile_dst==3`, inject 8 combinational-legal leftover beats on the shared stub R into the mux (ungated `cdc_rvalid=rvalid`). Grant register stays 0. `dma_r_valid` stays the legal WDMA `W_R` path only — not the inject. DUT-driven `dbg_tile_dst` only. No hierarchical force of `dst` / `TILE_DST`. No C-FIX. No `soc_top` / MIG.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / tile `dst`
- Raise grant; apply C-FIX / A2
- Inject on CDC-slave `dma_r_valid` (sealed RINJ bag)
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or `mig_native_wrap`
- `graph_late_materialize_00` / Phase 2
- Board / COM12 / bitstream / JTAG / F1x
- Product RTL edit
- BOARD_PASS / existence PASS
- Steal Grok R6 lock
