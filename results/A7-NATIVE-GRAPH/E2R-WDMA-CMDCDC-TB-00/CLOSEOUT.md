# E2R-WDMA-CMDCDC-TB-00 (Class B) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1B_CMDCDC_DISPATCH.md`  
**Claim scope:** Isolated cmd-FIFO XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1w exclusive: MGO=1 SGO=0 DMA_ST=0 TILE_DST=4. BIT `4933B19BCC6C06603979896565E31DCD9703AFF7FD99EA8CD564DA0E659C25D6` |
| UNKNOWN | Where `a7ng_wdma_cdc` drops `m_go` so `s_go` never pulses |
| H_CANDIDATE | `cmd_wr_en` fires but `cmd_rd_en`/`cmd_pend` never promote `s_go_r` |
| H_RIVAL | `cmd_full=1` or `cmd_empty` never clears |
| FALSIFIER | One `m_go` → `s_go` within 50 `s_clk` with the six probes logged |
| UNIT | One `m_go` command |
| CONTROL | Isolated DUT; `s_busy=0`; both rst released + XPM recovery |
| ONE CHANGE | Unit TB + XSim of `rtl/board/a7ng_wdma_cdc.sv` cmd path only |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (compile + run + probes recorded; marker `E2R_WDMA_CMDCDC_TB_XSIM_PASS`) |
| CLASS | **B** (silicon still MGO=1 SGO=0; this gate does not prove board `s_go`) |
| FIRST_MISSING_MARKER | **NONE** (XSim only) |
| H_CANDIDATE | **FALSIFIED** under isolated TB (`s_busy=0`) |
| H_RIVAL | **FALSIFIED** under isolated TB (`full=0`, empty cleared) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Probe summary (`m_go` vs six signals vs `s_go`)

| t (ns) | m_go | cmd_wr_en | cmd_full | cmd_empty | cmd_rd_en | cmd_pend | s_go_r | s_go |
|--------|------|-----------|----------|-----------|-----------|----------|--------|------|
| 5960000 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6040000 | 1 | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6175000 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| 6185000 | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 |
| 6195000 | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 1 |

`s_go` **8** `s_clk` after `m_go` (window=50). Full CSV: `probe_table.md` / `probe_table.csv`.

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
M_GO_PULSE T=5960000 wr_en=0 full=0 empty=1
PROBE t=6040000 clk=m m_go=1 s_go=0 wr_en=1 full=0 empty=1 rd_en=0 pend=0 s_go_r=0
PROBE t=6175000 clk=s m_go=0 s_go=0 wr_en=0 full=0 empty=0 rd_en=1 pend=0 s_go_r=0
PROBE t=6185000 clk=s m_go=0 s_go=0 wr_en=0 full=0 empty=1 rd_en=0 pend=1 s_go_r=0
S_GO_R T=6195000 s_cycles_after_m=8 empty=1 rd_en=0 pend=0
S_GO T=6195000 s_cycles_after_m=8 addr=0001000 bytes=64 wr=1
SUMMARY m_go=1 wr_en=1 empty_clr=1 rd_en=1 pend=1 s_go_r=1 s_go=1 s_cyc=50 full_final=0 empty_final=1
FIRST_MISSING_MARKER=NONE
E2R_WDMA_CMDCDC_TB_XSIM_PASS probes_recorded=1 s_go=1 marker=NONE window=50
```

DUT SHA256 `00F7845725682F251A673E5865A59057EDA5A8CD184A81128FC6B41CD02E80DA` (`a7ng_wdma_cdc.sv`). Vivado 2026.1. xelab unused-port WARNINGs only (`prog_full`).

## Interpretation

Isolated `a7ng_wdma_cdc` **does** promote one `m_go` to `s_go` when `s_busy=0` and both domains are out of reset with XPM recovery. Silicon F1w `SGO=0` is **not** explained by a cmd-FIFO / pend / `s_go_r` law failure under this stimulus. XSim ≠ board.

## NEXT_ONE_UNKNOWN

**silicon `s_busy` gating `cmd_rd_en`** (`cmd_rd_en` requires `!s_busy && cmd_st==C_IDLE`).  
Do **not** edit B1 / grant / `r_path_idle` / tile from this gate. Optional later: silicon rst/XPM write-drop if `s_busy` is proven 0.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame |
| `tb_e2r_wdma_cmdcdc_00.sv` | Isolated DUT TB |
| `tests/xsim/tb_e2r_wdma_cmdcdc_00.sv` | Canonical copy |
| `run_xsim.cmd` | xvlog / xelab (`-L xpm` + `glbl`) / xsim |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab |
| `probe_table.csv` / `PROBE_TABLE.md` | Waveform table |
