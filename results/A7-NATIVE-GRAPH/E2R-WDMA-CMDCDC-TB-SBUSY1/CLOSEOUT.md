# E2R-WDMA-CMDCDC-TB-SBUSY1 (Class B) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1B2_XSIM_SBUSY_DISPATCH.md`  
**Claim scope:** Isolated cmd-FIFO XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | TB-00 CONTROL (`s_busy=0`): one `m_go` → `cmd_rd_en=1` then `s_go=1` at 8 `s_clk`. RTL: `cmd_rd_en = … && !s_busy`. |
| UNKNOWN | Does `cmd_rd_en` stay 0 and `s_go` never fire while `s_busy=1` after one `m_go`? |
| H_CANDIDATE | Yes — preregistered B-FIX: `s_busy` gates `cmd_rd_en`. |
| H_RIVAL | `s_busy` unused/bypassed; `rd_en`/`s_go` still fire as in TB-00. |
| FALSIFIER | Any `cmd_rd_en=1` or `s_go=1` in the 50 `s_clk` window while `s_busy` held 1. |
| UNIT | One `m_go` command |
| CONTROL | `E2R-WDMA-CMDCDC-TB-00` same DUT/clocks/window, `s_busy=0`, `s_go=1` / `rd_en=1` |
| ONE CHANGE | TB variant holds `s_busy=1` after one `m_go`. No product RTL. |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_WDMA_CMDCDC_TB_SBUSY1_XSIM_PASS`) |
| s_go | **0** |
| cmd_rd_en ever | **0** |
| VERDICT | **B-FIX: s_busy gates rd** (`B_FIX_SUPPORTED`) |
| H_CANDIDATE | **supported** under this isolated TB |
| H_RIVAL | **falsified** under this isolated TB |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Probe contrast vs CONTROL

| t (ns) | event | TB-00 `s_busy=0` | this run `s_busy=1` |
|--------|-------|------------------|---------------------|
| 6040000 | write sampled | `cmd_wr_en=1` | `cmd_wr_en=1` |
| 6175000 | empty clears | `empty=0` **`rd_en=1`** | `empty=0` **`rd_en=0`** |
| 6195000 | CONTROL `s_go` | **`s_go=1`** | **`s_go=0`**, empty still 0 |

DUT-side stickies: `dbg_cmd_rd_sticky=0`, `dbg_sbusy_pend=1`, `dbg_cmd_empty_mgo=0`, `dbg_cmd_st=0` (C_IDLE). FIFO beat remains unread (`empty_final=0`).

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
M_GO_PULSE T=5960000 wr_en=0 full=0 empty=1 s_busy=1
SUMMARY m_go=1 wr_en=1 empty_clr=1 rd_en=0 pend=0 s_go_r=0 s_go=0 s_busy_held=1 s_cyc=50 full_final=0 empty_final=0
S_GO_SEEN=0 S_GO_R_SEEN=0 CMD_RD_EN_EVER=0 SBUSY_HELD=1
DBG_CMD_RD_STICKY=0 DBG_SBUSY_PEND=1 DBG_CMD_EMPTY_MGO=0 DBG_CMD_ST=0
VERDICT=B_FIX_SUPPORTED
EXISTENCE=not_claimed
E2R_WDMA_CMDCDC_TB_SBUSY1_XSIM_PASS probes_recorded=1 s_go=0 cmd_rd_en_ever=0 verdict=B_FIX_SUPPORTED window=50
```

DUT SHA256 `024CC88BFFC588F8C4527528E32B4C02BE6F90F363835055E4A72A46A072494D` (`a7ng_wdma_cdc.sv`). Vivado 2026.1. xelab unused-port WARNINGs only (`prog_full`).

## Interpretation

Isolated `a7ng_wdma_cdc` **does** withhold `cmd_rd_en` and `s_go` when `s_busy=1` after one accepted `m_go`. B-FIX is supported in XSim: `s_busy` gates rd. This does **not** prove silicon `s_busy` is 1, and does **not** claim existence. XSim ≠ board.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before run) |
| `tb_e2r_wdma_cmdcdc_sbusy1.sv` | Isolated DUT TB variant |
| `tests/xsim/tb_e2r_wdma_cmdcdc_sbusy1.sv` | Canonical copy |
| `run_xsim.cmd` | xvlog / xelab (`-L xpm` + `glbl`) / xsim |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab |
| `probe_table.csv` / `PROBE_TABLE.md` | Waveform table |
