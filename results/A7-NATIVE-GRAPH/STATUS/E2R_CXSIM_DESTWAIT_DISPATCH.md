# E2R C-XSIM-DESTWAIT — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-DESTWAIT-00/`  
**Do not program. Do not F1x. Do not write bitstream. Do not edit product RTL.**

This is the **dest-wait half** of the already-opened C-XSIM unknown (`E2R_CXSIM_DISPATCH.md`: “SOA done / dest wait”). Complete-query bags are SEALED `NONE`. Do not reopen them.

## Scientific frame

- **OBSERVATION:** Silicon B-FIX UART `TILE_DST=4` `RPATH_IDLE=0` `GRANT=0` `SGO=0` `pred` absent (BIT `6023D9A3…`). Complete-query XSim (isolated/INT/CDC) shows idle=1 after SOA drain.
- **UNKNOWN (same):** which of `r_drain_hold`, `fifo_cnt!=0`, `m_axi_rvalid`, `tr_cnt!=0` keeps `r_path_idle=0` **at legal dest-wait** (`TILE_DST=4` / `D_WAITDONE`).
- **H_CANDIDATE:** at dest-wait, `m_axi_rvalid` leftover (mux/MIG/stub R) holds idle=0.
- **H_RIVAL:** `fifo_cnt` or `tr_cnt` leftover; or dest-wait TB also idle=1 (`NONE` — leftover not on this stub path).
- **FALSIFIER:** never reach legal `TILE_DST==4` inside bound (`FAIL_NO_DESTWAIT`); more than one constituent independently 1 (`SET`, no C-FIX); force/`assign` of `TILE_DST` or `r_path_idle`.
- **UNIT:** first occupancy of legal dest-wait after one query start — not a clock-cycle farm.
- **CONTROL:** C-XSIM isolated/INT/CDC complete-query idle=1; silicon dest-wait `RPATH_IDLE=0`.
- **METRICS:** `dbg_tile_dst`, `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt`, `r_path_idle`, `wdma_owner`, `wdma_owner_grant` at first dest-wait cycle.

## How to hit dest-wait (legal)

Instantiate `a7ng_native_v1_ab_core` with `SIM_FULL=0` (silicon SoC uses 0). Wire `r_path_idle_o` and `dbg_tile_dst_o`. `do_lm=1`.

`weight_tile803k`: `D_IDLE→D_GO` needs `req && !dma_busy`; `D_GO→D_DRAIN` needs `dma_busy`; `D_DRAIN→D_WAITDONE` needs 8 `dma_r_valid` beats. Leaving `wdma_busy=0` (core default) **sticks at D_GO=1**, never 4.

Legal WDMA responder (TB only): on `wdma_go` assert busy, return 8 read beats, then **hold busy=1 and done=0** so DUT dest stays `D_WAITDONE`. That matches silicon “wait for WDMA done”. Do not hierarchical-force `dst`.

Start from `tb_a7ng_native_v1_ab_fast.sv` / `run_a7ng_native_v1_ab_fast.tcl` as a copy — do not edit the sealed fast bag in place.

**Forbidden:** hierarchical force of `TILE_DST` / `dst`; UART-latch poke; `assign r_path_idle=1`; B1 grant/`soa_done` edit; unbounded full MIG TB as the only plan; `SIM_FULL=1` as a substitute for dest-wait.

If dest-wait is not reached in a bounded run (`FAIL_NO_DESTWAIT`), stop. Do not fake it.

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | exactly one named AND term is 1 at first dest-wait | name that wire only; do **not** apply C-FIX in this bag |
| `SET` | two or more terms 1 | no C-FIX |
| `NONE` | dest-wait reached and all four clear / idle=1 | no C-FIX |
| `FAIL_NO_DESTWAIT` | never `TILE_DST==4` | no C-FIX |

## Done

Archive TB/Tcl/log + `CLOSEOUT.md` under the results dir. Parent writes `STATUS/E2R_CXSIM_DESTWAIT_CLOSEOUT.md`. No board. No BOARD_PASS.
