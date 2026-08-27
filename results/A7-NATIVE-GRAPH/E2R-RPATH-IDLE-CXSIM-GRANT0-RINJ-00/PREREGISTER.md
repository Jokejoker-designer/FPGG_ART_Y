# E2R-RPATH-IDLE-CXSIM-GRANT0-RINJ-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_RINJ_DISPATCH.md`  
**Prior bag (control, not this UNIT):** GRANT0 no-inject dest=3, grant=0, SHA `E2B2BA9A…`  
**Class:** C-XSIM grant=0 leftover-R dest-wait  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before first dest=4 snapshot)

| Field | Value |
|-------|-------|
| OBSERVATION | GRANT0 dest starved at `D_DRAIN=3` without R (`GRANT_STAYED_0=1`). Silicon UART same-cycle latch: `TILE_DST=4` `GRANT=0` `OWNER=1`. Mechanism left open: leftover R completing drain without grant. |
| UNKNOWN | With grant held 0 from reset, after DUT `dbg_tile_dst` first reaches 3, do 8 TB-injected WDMA R beats (`dma_r_valid` on CDC slave R toward the tile) make DUT-driven `dbg_tile_dst==4`? |
| H_CANDIDATE | Yes — leftover R can complete drain without grant (silicon pair possible on this vehicle). Then classify four idle AND terms at first dest=4 (`ONE`/`SET`/`NONE`). |
| H_RIVAL | dest stays 3 after 8 R (`FAIL_NO_DESTWAIT_GRANT0`) — leftover R is not enough; silicon pair still unreproduced. |
| FALSIFIER | Force `dst` / `TILE_DST`; raise grant; product RTL; C-FIX; A2; board; `soc_top`+MIG only. |
| UNIT | One query; grant=0 from reset; inject exactly 8 R after first dest==3. Not a cycle farm. |
| CONTROL | GRANT0 no-inject dest=3 (SHA `E2B2BA9A…`); mux dest=4 only after grant. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | dest before/after inject, grant (must stay 0), owner, four AND terms, idle if dest=4, R_INJECTED. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | dest=4, grant stayed 0, exactly one AND term 1 | name only |
| `SET` | dest=4, grant stayed 0, >1 term | none |
| `NONE` | dest=4, grant stayed 0, idle=1 / n_hot=0 | none |
| `FAIL_NO_DESTWAIT_GRANT0` | dest never 4 after 8 R | none |

Marker `E2R_RPATH_IDLE_CXSIM_GRANT0_RINJ_00_XSIM_PASS` only if dest=4, grant stayed 0, and classified.

## Legal dest-wait (declared)

Copy of GRANT0 TB. `a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. Same mux vehicle. **TB-only delta:** after first `dbg_tile_dst==3`, inject 8 combinational-legal R beats on CDC slave `dma_r_valid` toward the tile. Grant register stays 0. DUT-driven `dbg_tile_dst` only. No hierarchical force of `dst` / `TILE_DST`. No C-FIX. No `soc_top` / MIG.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / tile `dst`
- Raise grant; apply C-FIX / A2
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or `mig_native_wrap`
- `graph_late_materialize_00` / Phase 2
- Board / COM12 / bitstream / JTAG / F1x
- Product RTL edit
- BOARD_PASS / existence PASS
- Steal Grok R6 lock
