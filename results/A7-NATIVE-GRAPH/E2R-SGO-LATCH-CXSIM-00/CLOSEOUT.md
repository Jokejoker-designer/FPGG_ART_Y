# E2R-SGO-LATCH-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SGO_LATCH_CXSIM_DISPATCH.md`  
**Claim scope:** TB replica of SoC F1u `latched_sgo_f1u` on the SGO-MUX occupancy — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no force dest; no `assign r_path_idle=1`; `s_dma_idle` kept `1'b0`; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | SGO-MUX `SGO_ROSE` (sticky=1 at dest=4). SoC UART `SGO` is `latched_sgo_f1u <= wdma_dbg_sgo` while `sticky_qgo_ui && core_busy_ui`. Silicon sequential `SGO=0`. |
| UNKNOWN | On dest=4 grant=1 leftover SET with sticky=1, does a TB replica of `latched_sgo_f1u` equal 1? |
| H_CANDIDATE | `LATCH_MISS` — sticky=1 and latch=0 at dest=4 **and** at end. |
| H_RIVAL | `LATCH_HIT` — latch=1 at dest=4 or end when sticky=1. |
| FALSIFIER | Edit SoC; C-FIX; A2; LiteScope; `soc_top`+MIG; force dest; retie `s_dma_idle`. |
| UNIT | One query. First dest=4 (`snap_cyc=355`) + 128-cycle end settle. |
| CONTROL | SGO-MUX `SGO_ROSE` SHA `68B3280522FAEB1FBA67E89E96C17BC608AB0D7337B8752216420F09ADA3E189`; SoC `sync_bits` + F1u latch; `s_dma_idle=1'b0`. |
| METRICS | sticky, `core_busy`, `core_busy_ui`, `latched_sgo` at dest=4 and at end. |

## Vehicle (TB-only vs SGO-MUX)

Copy of `tb_e2r_sgo_cxsim_mux_00.sv`. Kept mux + B1 + shared stub + `s_dma_idle=1'b0` + hold busy after 8 R. `SIM_FULL=0`. DUT-driven dest=4 only. No `soc_top`.

**One change:** TB replica of SoC F1u latch. `sticky_qgo` set on TB `start` (SoC `start_q` analogue). Existing `sync_bits` (2-FF, same module as SoC `u_core_busy_ui` / `u_qgo_ui`) for `core_busy`→`core_busy_ui` and `sticky_qgo`→`sticky_qgo_ui`. Latch: `latched_sgo_f1u <= dbg_s_go_sticky` while `sticky_qgo_ui && core_busy_ui`.

## First dest=4 snapshot (UNIT)

| Metric | dest=4 | end |
|--------|--------|-----|
| `dbg_tile_dst` | **4** | **4** |
| `wdma_owner_grant` | **1** | **1** |
| leftover AND | fifo + `c_rvalid` (`n_hot=2`) | same |
| `dbg_s_go_sticky` | **1** | **1** |
| `latched_sgo_f1u` | **1** | **1** |
| `core_busy` | **1** | **1** |
| `core_busy_ui` | **1** | **1** |
| `sticky_qgo` / `sticky_qgo_ui` | **1** / **1** | **1** / **1** |

`WDMA_GO` (t=26760000, dest=0): `core_busy=1` `core_busy_ui=1` `qgo_ui=1` `latch_sgo=0` (sticky not yet 1). Dest-wait at t=29640000: sticky=1 and latch=1.

## Verdict

| Field | Value |
|-------|-------|
| GATE | `E2R-SGO-LATCH-CXSIM-00` |
| XSIM | **PASS** (`E2R_SGO_LATCH_CXSIM_00_XSIM_PASS`) |
| CLASS | **LATCH_HIT** |
| LATCHED_AT_DEST4 | **1** |
| STICKY_AT_DEST4 | **1** |
| CORE_BUSY_UI | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this mux+stub vehicle (latch not 0 while sticky=1) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA s_dma_idle=0 F1U_LATCH_REPLICA
PROBE t=26760000 phase=WDMA_GO dst=0 core_busy=1 core_busy_ui=1 qgo=1 qgo_ui=1 latch_sgo=0 sgo_st=0
PROBE t=29640000 phase=FIRST_DESTWAIT dst=4 fifo=4 c_rvalid=1 grant=1 sgo_st=1 core_busy=1 core_busy_ui=1 latch_sgo=1
PROBE t=39880000 phase=END_SETTLE dst=4 sgo_st=1 latch_sgo=1 core_busy=1 core_busy_ui=1
SNAP_LATCH latch=1 core_busy=1 core_busy_ui=1 qgo=1 qgo_ui=1
END_LATCH latch=1 core_busy=1 core_busy_ui=1 qgo=1 qgo_ui=1
SGO_STICKY_AT_DEST4=1
LATCHED_AT_DEST4=1
CORE_BUSY_UI_AT_DEST4=1
CLASS=LATCH_HIT
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_SGO_LATCH_CXSIM_00_XSIM_PASS class=LATCH_HIT c_fix=NONE dst=4 grant=1 idle=0 fifo=4 c_rvalid=1 sgo_st_dest4=1 sgo_st_end=1 latch_dest4=1 latch_end=1 core_busy=1 core_busy_ui=1
```

Log SHA256 `74433CAE2917FCACDBA48CDEF85A194A79376E45CC195D7213F13B4C737068AB` (`xsim.log`).  
TB SHA256 `68312383DAB374F80FCB65A37515E33FA493822E11DB34F34C0885FD83C41BD1` (`tb_e2r_sgo_latch_cxsim_00.sv`).  
CONTROL SGO-MUX SHA256 `68B3280522FAEB1FBA67E89E96C17BC608AB0D7337B8752216420F09ADA3E189` (unchanged).  
CDC SHA256 `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` (`a7ng_wdma_cdc.sv`, not edited).  
`sync_bits` SHA256 `D42DF79D6858DCA8A59A4B63BA6FC9C6FE82A954FD75F4677CF9451BA1BF8996` (not edited).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait occupancy matched CONTROL: dest=4 grant=1 idle=0 fifo=4 `c_rvalid=1`, sticky=1. On that UNIT the TB latch enable (`sticky_qgo_ui && core_busy_ui`) was 1, and `latched_sgo_f1u` copied sticky → 1 at dest=4 and at end.

That **supports** H_RIVAL `LATCH_HIT` and **falsifies** H_CANDIDATE `LATCH_MISS` on this stimulus: a CDC / `core_busy_ui` miss is not required to explain dest-wait `SGO=0` here. The UART print path, if it sees this occupancy with `core_busy_ui=1`, would latch 1.

This does **not** prove silicon `SGO=1`. XSim stub+CDC ≠ board UART. Silicon sequential `SGO=0` is **not** sold as GRANT-skew. Grant still rose before dest-wait (`grant_rose=1`), same MUX deviation vs silicon dest-wait `GRANT=0` on sequential prints. One query, one occupancy — not a cycle farm.

**No C-FIX.** Latch replica is TB-only. Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_sgo_latch_cxsim_00.sv` | Canonical TB |
| `tb_e2r_sgo_latch_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_sgo_latch_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | dest + latch table |
| `log.jsonl` | Gate log line |
