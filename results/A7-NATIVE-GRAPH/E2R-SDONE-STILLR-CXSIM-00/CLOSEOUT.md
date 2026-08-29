# E2R-SDONE-STILLR-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_STILLR_CXSIM_DISPATCH.md`  
**Claim scope:** Mux leftover XSim, still-in-R dest=4 snap of `dbg_s_done_sticky` only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no complete before dest=4; no hold-forever after dest=4; no force dest; no `assign r_path_idle=1`; `s_dma_idle` kept `1'b0`; no `soc_top` / MIG)

XSim ≠ board. Sequential UART `SDONE=0` is **not** answered by this bag.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | ROSE bag finished first burst before dest=4 (`snap w_st=0`, sticky already 1). Silicon ATOMIC-SGO dest=4 still-in-R (`dma_st=5`). Occupancies differ. Sequential `SDONE=0` unanswered. |
| UNKNOWN | At first dest=4 ∧ grant=1 ∧ leftover SET, if the responder is still busy/in-R (then completes later), is `dbg_s_done_sticky` 0 or 1? |
| H_CANDIDATE | `SNAP_DONE0` — sticky=0 at dest=4 while in-R. Silicon `SDONE=0` can be same-cycle still-in-R. |
| H_RIVAL | `SNAP_DONE1` — sticky=1 at dest=4 even while current burst in-R (prior done). |
| FALSIFIER | Complete before dest=4 (ROSE); hold forever (MUX); C-FIX; A2; LiteScope; `soc_top`+MIG; force dest. |
| UNIT | One query. First dest=4 snap (`snap_cyc=355`). After-complete sticky is secondary, not a second unknown. |
| CONTROL | SDONE-CXSIM ROSE SHA `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520`; ATOMIC-SGO `dma_st=5`; sequential `SDONE=0`. |
| METRICS | dest, leftover, in-R/busy at snap, `s_go` ever, sticky at dest=4, sticky after later complete. |

## Vehicle (TB-only vs ROSE CONTROL)

Copy of `tb_e2r_sdone_cxsim_00.sv` (ROSE TB SHA `7A9C01D4…`). Kept mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest=4 only.

**One change:** do not pulse `s_done` / clear busy until after first dest=4 is latched (`destwait_seen` 2-FF to `dest4_seen_ui`); stay in `W_R` with `busy=1` through that snap, then complete. Completing before dest=4 is the ROSE FALSIFIER. Holding forever after dest=4 is the MUX FALSIFIER.

## First dest=4 snapshot (UNIT)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` | **4** |
| `wdma_owner_grant` | **1** |
| `r_path_idle` | **0** |
| `fifo_cnt` | **4** |
| `c_rvalid` | **1** |
| leftover AND | `fifo` + `c_rvalid` (`n_hot=2`, SET) |
| in-R/busy at snap | **1** (`w_st=3` `W_R`, `s_busy=1`, `m_busy=1`) |
| `s_go` ever | **1** |
| `dbg_s_done_sticky` at dest=4 | **0** |
| `s_done` ever at dest=4 | **0** |
| `dbg_s_done_sticky` after later complete | **1** |
| `dbg_m_done_sticky` at dest=4 | **0** |

Dest-wait latch at t=29640000 (`snap_cyc=355`), same cycle count as ROSE. ROSE snap was `w_st=0` sticky=1 (first burst already complete). This snap is `w_st=3` sticky=0 (still in-R). Live `FIRST_DESTWAIT` print is one `core_clk` later and already shows sticky=1 — after-snap complete, not the UNIT snap.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-SDONE-STILLR-CXSIM-00** |
| XSIM | **PASS** (`E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS`) |
| CLASS | **SNAP_DONE0** |
| DEST4 | **1** |
| IN_R_AT_SNAP | **1** |
| S_DONE_STICKY_AT_DEST4 | **0** |
| S_DONE_AFTER_COMPLETE | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** on this still-in-R vehicle (sticky=0 at dest=4 while in-R) |
| H_RIVAL | **not supported** on this vehicle (sticky was not 1 at the in-R snap) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

n = 1 query (one UNIT). Descriptive class only. Not a cycle farm.

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA STILLR_THEN_COMPLETE s_dma_idle=0
PROBE t=26760000 phase=WDMA_GO dst=0 idle=1 own=1 grant=1 m_go=1 s_go=0 sdone_ever=0
PROBE t=29640000 phase=FIRST_DESTWAIT dst=4 fifo=4 c_rvalid=1 idle=0 grant=1 own_ui=1 sgo_st=1 sgo_ever=1 s_done=0 sdone_st=1 mdone_st=0 sdone_ever=1 s_busy=1 m_busy=1 rleft=3 wst=3
REACHED_DESTWAIT=1 FIRST_TILE_DST=4
SNAP destwait_cyc=355 drain=0 fifo=4 c_rvalid=1 idle=0 grant=1
SNAP_SDONE sdone_st=0 mdone_st=0 sdone_ever=0 s_busy=1 m_busy=1 wst=3
END_SDONE sdone_st=1 mdone_st=1 sdone_ever=1
IN_R_AT_SNAP=1
S_DONE_STICKY_AT_DEST4=0
S_DONE_AFTER_COMPLETE=1
DEST4=1
CLASS=SNAP_DONE0
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS class=SNAP_DONE0 c_fix=NONE dst=4 grant=1 idle=0 fifo=4 c_rvalid=1 in_r=1 sgo_ever=1 sdone_st_dest4=0 sdone_after_complete=1 s_busy_dest4=1 wst_snap=3
```

Log SHA256 `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7` (`xsim.log`).  
TB SHA256 `013BA2A8006786B7F844E38DD4EF180DBD82E0DBF425314CB4BA0E3AD5FD1A62` (`tb_e2r_sdone_stillr_cxsim_00.sv`).  
ROSE control SHA256 `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520` (`E2R-SDONE-CXSIM-00/xsim.log`, not re-run).  
CDC SHA256 `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` (`a7ng_wdma_cdc.sv`, not edited).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait occupancy matched CONTROL/ATOM leftover: dest=4 grant=1 idle=0 fifo=4 `c_rvalid=1`. On that UNIT the responder was still in-R/busy (`w_st=3`, `s_busy=1`, `m_busy=1`) and `dbg_s_done_sticky` was **0**. After the snap, the burst was allowed to complete; end sticky / `s_done` ever became **1** (secondary metric). That **supports** H_CANDIDATE `SNAP_DONE0` and **does not support** H_RIVAL `SNAP_DONE1` on this stimulus.

ROSE FALSIFIER avoided: first dest=4 was not taken after an already-complete first burst (`snap w_st=0` sticky=1 in ROSE). MUX FALSIFIER avoided: busy was not held forever after dest=4.

This does **not** prove silicon `SDONE=0`. XSim stub+CDC ≠ board UART / MIG. Silicon ATOMIC-SGO dest=4 `dma_st=5(R)` is a still-in-R occupancy; this bag now shares that occupancy class and shows sticky=0 at the snap, which is **compatible** with sequential UART `SDONE=0` but is not a silicon measurement. Grant still rose before dest-wait (`grant_rose=1`), same MUX deviation vs silicon sequential `GRANT=0`. Leftover AND remains `fifo`+`c_rvalid` (`AMBIGUOUS`, `n_hot=2`). One query, one occupancy — not a cycle farm.

**No C-FIX.** Still-in-R-then-complete TB change is not a product patch. Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_sdone_stillr_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_sdone_stillr_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_sdone_stillr_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_sdone_stillr_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | dest + SDONE table |
| `log.jsonl` | Gate log line |
