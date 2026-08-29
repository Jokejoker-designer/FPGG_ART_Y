# E2R-SGO-CXSIM-MUX-00 — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SGO_CXSIM_MUX_DISPATCH.md`  
**Claim scope:** Mux leftover XSim, `dbg_s_go_sticky` only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no force dest; no `assign r_path_idle=1`; `s_dma_idle` kept `1'b0`; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1x ATOM dest=4 grant=1 idle=0 fifo_ne+c_rvalid. Sequential UART `SGO=0` is not same-cycle. MUX printed `go=` as `wdma_go` (`m_go`); `dbg_s_go_sticky` was unconnected. |
| UNKNOWN | On first dest=4 ∧ grant=1 ∧ leftover SET, does `dbg_s_go_sticky` rise? |
| H_CANDIDATE | sticky=0 whole query (`SGO_NEVER`) — silicon `SGO=0` can be a true miss. |
| H_RIVAL | sticky=1 at or before first dest=4 (`SGO_ROSE`) — UART `SGO=0` is print-time like GRANT skew. |
| FALSIFIER | Force dest; C-FIX; A2; LiteScope; `soc_top`+MIG; retie `s_dma_idle`. |
| UNIT | One query. First dest=4 snapshot (`snap_cyc=355`). Not a cycle farm. |
| CONTROL | MUX dest=4 grant=1 leftover SET; F1x ATOM same leftover pair grant=1; silicon sequential `SGO=0`. |
| METRICS | dest, grant, idle, fifo, c_rvalid, `s_go` ever, sticky at dest=4 and end, `dbg_m_go_sticky`, `dbg_cmd_st`, `dbg_sbusy_pend`, `dbg_cmd_rd_sticky`. |

## Vehicle (TB-only vs MUX)

Copy of `tb_e2r_rpath_idle_cxsim_mux_00.sv`. Kept mux + B1 + shared stub + `s_dma_idle=1'b0` + hold busy after 8 R. `SIM_FULL=0`. DUT-driven dest=4 only.

**One change:** wire `dbg_s_go_sticky` / `dbg_m_go_sticky` / cmd probes (MUX left them open). Print `m_go` and `s_go` as separate fields.

## First dest=4 snapshot (UNIT)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` | **4** |
| `wdma_owner_grant` | **1** |
| `r_path_idle` | **0** |
| `fifo_cnt` | **4** |
| `c_rvalid` | **1** |
| leftover AND | `fifo` + `c_rvalid` (`n_hot=2`, SET) |
| `s_go` pulse at snap | 0 (already consumed) |
| `s_go` ever | **1** |
| `dbg_s_go_sticky` at dest=4 | **1** |
| `dbg_s_go_sticky` at end | **1** |
| `dbg_m_go_sticky` | **1** |
| `dbg_cmd_st` | **2** (`C_BUSY`) |
| `dbg_sbusy_pend` | **1** |
| `dbg_cmd_rd_sticky` | **1** |
| `dbg_cmd_empty_mgo` | 0 |

`WDMA_GO` (t=26760000, dest=0): `m_go=1` `s_go=0` stickies still 0 (same-cycle as `m_go`). Dest-wait at t=29640000 after shared-bus 8 R / `W_HOLD`.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_SGO_CXSIM_MUX_00_XSIM_PASS`) |
| CLASS | **SGO_ROSE** |
| SGO_STICKY_AT_DEST4 | **1** |
| SGO_STICKY_END | **1** |
| MGO_STICKY | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this mux+stub vehicle (sticky not 0 for the query) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA s_dma_idle=0
PROBE t=26760000 phase=WDMA_GO dst=0 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=1 own_ui=0 m_go=1 s_go=0 sgo_st=0 mgo_st=0 sgo_ever=0 cmd_st=0
PROBE t=29640000 phase=FIRST_DESTWAIT dst=4 drain=0 fifo=4 c_rvalid=1 tr=0 idle=0 own=1 grant=1 own_ui=1 m_go=0 s_go=0 sgo_st=1 mgo_st=1 sgo_ever=1 cmd_st=2 sbusy_pend=1 cmd_rd=1
PROBE t=39880000 phase=END_SETTLE dst=4 fifo=4 idle=0 grant=1 sgo_st=1 mgo_st=1 sgo_ever=1 cmd_st=2
SNAP destwait_cyc=355 drain=0 fifo=4 c_rvalid=1 idle=0 grant=1
SGO_STICKY_AT_DEST4=1
SGO_STICKY_END=1
MGO_STICKY=1
CLASS=SGO_ROSE
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_SGO_CXSIM_MUX_00_XSIM_PASS class=SGO_ROSE c_fix=NONE dst=4 grant=1 idle=0 fifo=4 c_rvalid=1 sgo_st_dest4=1 sgo_st_end=1 mgo_st=1 sgo_ever=1
```

Log SHA256 `68B3280522FAEB1FBA67E89E96C17BC608AB0D7337B8752216420F09ADA3E189` (`xsim.log`).  
TB SHA256 `FE7CD3878A6AB4B56601C9227AD747DD41A3B47DE7D9D314B8E7201F3DB1684D` (`tb_e2r_sgo_cxsim_mux_00.sv`).  
CDC SHA256 `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` (`a7ng_wdma_cdc.sv`, not edited).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait occupancy matched CONTROL/ATOM leftover: dest=4 grant=1 idle=0 fifo=4 `c_rvalid=1`. On that UNIT, `dbg_s_go_sticky` was already 1. `s_go` ever=1 and `cmd_rd_sticky=1` (`cmd_st=C_BUSY`). Live `s_go` at the dest=4 dump is 0 because the pulse is gone — sticky holds the fact.

That **supports** H_RIVAL on this stimulus and **falsifies** H_CANDIDATE `SGO_NEVER` on this vehicle: a true miss of `s_go` is not required to explain dest-wait `SGO=0` here. Sequential UART `SGO=0` is compatible with print-time (pulse already consumed), like GRANT skew vs ATOM.

This does **not** prove silicon `s_go` rose. XSim stub+CDC ≠ board UART. Grant still rose before dest-wait (`grant_rose=1`), same MUX deviation vs silicon dest-wait `GRANT=0` on sequential prints. One query, one occupancy — not a cycle farm.

**No C-FIX.** Wiring probes is not a product patch. Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_sgo_cxsim_mux_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_sgo_cxsim_mux_00.tcl` | Canonical tcl |
| `tb_e2r_sgo_cxsim_mux_00.sv` | Copy used by xvlog cwd |
| `run_e2r_sgo_cxsim_mux_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | dest + SGO sticky table |
| `log.jsonl` | Gate log line |
