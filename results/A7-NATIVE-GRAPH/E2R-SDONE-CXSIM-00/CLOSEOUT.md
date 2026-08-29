# E2R-SDONE-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_CXSIM_DISPATCH.md`  
**Claim scope:** Mux leftover XSim, completable-responder `s_done` / `dbg_s_done_sticky` only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no hold-busy after 8 R; no force dest; no `assign r_path_idle=1`; `s_dma_idle` kept `1'b0`; no `soc_top` / MIG)

XSim ≠ board. UART `SDONE=0` is not this bag.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon SGO_HIT and DMA in R at dest=4. UART `SDONE=0`. Old MUX bag forced hold-busy after 8 R. |
| UNKNOWN | On dest=4 ∧ grant=1 ∧ leftover SET ∧ `s_go` fired, if the WDMA responder completes, does `s_done` / `dbg_s_done_sticky` rise? |
| H_CANDIDATE | `SDONE_NEVER` — leftover SET keeps DMA in R; done never. |
| H_RIVAL | `SDONE_ROSE` — done rises after complete beats. Silicon `SDONE=0` is stub≠board / still-in-R. |
| FALSIFIER | Hold `busy=1` `done=0` after 8 R; C-FIX; A2; `soc_top`+MIG; force dest. |
| UNIT | One query. First dest=4 snapshot (`snap_cyc=355`) + whether done ever in that query. |
| CONTROL | MUX hold-busy (done forced 0); ATOMIC-SGO dma_st=5; sequential `SDONE=0`. |
| METRICS | dest, grant, leftover, `s_go` ever, `s_done` ever, `dbg_s_done_sticky`, `w_st`, busy at dest=4 and end. |

## Vehicle (TB-only vs MUX / LATCH CONTROL)

Copy of `tb_e2r_sgo_cxsim_mux_00.sv`. LATCH CONTROL is the same hold-busy responder plus a UART latch replica (not instantiated here). Kept mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest=4 only.

**One change:** after 8 shared-stub R beats, pulse `s_done` and clear `s_busy` (completable responder). `s_dma_idle` stays CONTROL `1'b0` — the idle pin is not the responder done bit and was not retied.

## First dest=4 snapshot (UNIT)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` | **4** |
| `wdma_owner_grant` | **1** |
| `r_path_idle` | **0** |
| `fifo_cnt` | **4** |
| `c_rvalid` | **1** |
| leftover AND | `fifo` + `c_rvalid` (`n_hot=2`, SET) |
| `s_go` ever | **1** |
| `s_done` ever | **1** |
| `dbg_s_done_sticky` at dest=4 | **1** |
| `dbg_s_done_sticky` at end | **1** |
| `dbg_m_done_sticky` | **1** |
| `s_busy` at dest=4 | **1** |
| `m_busy` at dest=4 | **0** |
| snap `w_st` | **0** (`W_IDLE` — first burst already complete) |

`WDMA_GO` (t=26760000, dest=0): `m_go=1` `s_go=0` stickies still 0. Dest-wait latch at t=29640000 (`snap_cyc=355`) after the first shared-bus 8 R completed. Live `FIRST_DESTWAIT` print is dest=5 `w_st=3` `rleft=8` (a later burst already in R). END leftover still SET; live dest=0 after grant drop.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-SDONE-CXSIM-00** |
| XSIM | **PASS** (`E2R_SDONE_CXSIM_00_XSIM_PASS`) |
| CLASS | **SDONE_ROSE** |
| S_DONE_EVER | **1** |
| S_GO_EVER | **1** |
| DEST4 | **1** |
| S_DONE_STICKY_AT_DEST4 | **1** |
| S_DONE_STICKY_END | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this mux+stub completable vehicle (done not never) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

n = 1 query (one UNIT). Descriptive class only. Not a cycle farm.

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA COMPLETABLE_RESPONDER s_dma_idle=0
PROBE t=26760000 phase=WDMA_GO dst=0 idle=1 own=1 grant=1 m_go=1 s_go=0 sdone_ever=0
PROBE t=29640000 phase=FIRST_DESTWAIT dst=5 fifo=4 c_rvalid=1 idle=0 grant=1 own_ui=1 sgo_st=1 sgo_ever=1 sdone_st=1 mdone_st=1 sdone_ever=1 s_busy=1 m_busy=0 rleft=8 wst=3
REACHED_DESTWAIT=1 FIRST_TILE_DST=4
SNAP destwait_cyc=355 drain=0 fifo=4 c_rvalid=1 idle=0 grant=1
SNAP_SDONE sdone_st=1 mdone_st=1 sdone_ever=1 s_busy=1 m_busy=0 wst=0
S_DONE_EVER=1
SGO_EVER=1
DEST4=1
CLASS=SDONE_ROSE
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_SDONE_CXSIM_00_XSIM_PASS class=SDONE_ROSE c_fix=NONE dst=4 grant=1 idle=0 fifo=4 c_rvalid=1 sgo_ever=1 sdone_ever=1 sdone_st_dest4=1 sdone_st_end=1
```

Log SHA256 `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520` (`xsim.log`).  
TB SHA256 `7A9C01D4BA6E2AB3477C82C0AD3E77B78A0AD888DF84FA931B3EBB7649E320C8` (`tb_e2r_sdone_cxsim_00.sv`).  
CDC SHA256 `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` (`a7ng_wdma_cdc.sv`, not edited).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait occupancy matched CONTROL/ATOM leftover: dest=4 grant=1 idle=0 fifo=4 `c_rvalid=1`. On that UNIT, `s_go` ever=1 and `s_done` / `dbg_s_done_sticky` were already 1. Snap `w_st=0` means the first completable 8-R burst had already returned to idle before the dest=4 latch. Leftover SET did not keep that first burst in R and did not prevent `s_done`.

That **supports** H_RIVAL on this stimulus and **falsifies** H_CANDIDATE `SDONE_NEVER` on this vehicle: leftover SET is not sufficient to make done never when the responder is allowed to complete.

This does **not** prove silicon `s_done` rose. XSim stub+CDC ≠ board UART / MIG. Silicon ATOMIC-SGO dest=4 with `dma_st=5(R)` is a still-in-R occupancy; this bag’s first burst finished before dest=4, and a later burst was already in R on the live dest-wait print (`w_st=3` `rleft=8`). Sequential UART `SDONE=0` remains compatible with still-in-R / print-time / stub≠board. Grant still rose before dest-wait (`grant_rose=1`), same MUX deviation vs silicon sequential `GRANT=0`. Completing busy changed END live dest (0) vs MUX hold-busy END dest=4 — vehicle difference, not a product patch. One query, one occupancy — not a cycle farm.

**No C-FIX.** Completable-responder TB change is not a product patch. Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_sdone_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_sdone_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_sdone_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_sdone_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | dest + SDONE table |
| `log.jsonl` | Gate log line |
