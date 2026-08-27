# E2R-WDMA-CMDCDC-TB-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1B_CMDCDC_DISPATCH.md` (main repo)  
**Class:** B (silicon MGO=1 SGO=0)  
**Board:** NOT used. No program. No COM12.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1w exclusive silicon: MGO=1 SGO=0 DMA_ST=0 TILE_DST=4. BIT `4933B19BCC6C06603979896565E31DCD9703AFF7FD99EA8CD564DA0E659C25D6` |
| UNKNOWN | Where `a7ng_wdma_cdc` drops `m_go` so `s_go` never pulses: cmd FIFO full, empty stuck, rd_en never, pend stuck, or rst |
| H_CANDIDATE | `cmd_wr_en` fires but `cmd_rd_en`/`cmd_pend` never promote `s_go_r` (FIFO/rst/pending) |
| H_RIVAL | `cmd_full=1` or `cmd_empty` never clears — write accepted on paper, no read-side beat |
| FALSIFIER | One `m_go` pulse → `s_go` within 50 `s_clk` with probes logged |
| UNIT | One `m_go` command (not clock-cycle farm) |
| CONTROL | Isolated DUT; `s_busy=0` (matches silicon DMA_ST=0 / tile idle); both rst released + XPM recovery |
| METRICS | XSIM_PASS if TB compiles and records `cmd_wr_en/full/empty/rd_en/pend/s_go_r` vs `m_go`/`s_go` |

## ONE CHANGE

Unit TB + XSim of `rtl/board/a7ng_wdma_cdc.sv` **cmd FIFO only**.  
**No** B1 / grant / `r_path_idle` / tile / board program. **No** product RTL edit.

## DUT freeze (observation)

| Item | Value |
|------|-------|
| File | `rtl/board/a7ng_wdma_cdc.sv` |
| SHA256 | `00F7845725682F251A673E5865A59057EDA5A8CD184A81128FC6B41CD02E80DA` |
| cmd FIFO | `READ_MODE("std")`, `FIFO_READ_LATENCY(1)`, `CDC_SYNC_STAGES(3)`, `.rst(!m_rst_n)` |
| Write | `cmd_wr_en = m_rst_n && m_go && !cmd_full` |
| Read | `cmd_rd_en = s_rst_n && (cmd_st==C_IDLE) && !cmd_pend && !cmd_empty && !s_busy` |

## Protocol

1. Instantiate **only** `a7ng_wdma_cdc` (+ Vivado `xpm` lib + `glbl`).
2. `m_clk` 80 ns (12.5 MHz core); `s_clk` 10 ns (100 MHz ui stand-in).
3. Hold both resets ≥25 m_clk; release; XPM recovery (40 m + 80 s).
4. Pulse **one** `m_go` for 1 m_clk. `s_busy=0`. `s_done=0`.
5. Log `m_go`, `cmd_wr_en`, `cmd_full`, `cmd_empty`, `cmd_rd_en`, `cmd_pend`, `s_go_r`, `s_go`.
6. Watch 50 `s_clk` after `m_go`.
7. `FIRST_MISSING_MARKER` = first of `{cmd_wr_en, cmd_empty, cmd_rd_en, cmd_pend, s_go_r}` never seen; else `NONE`.

## Interpretation (post-run)

| TB result | Favored | Next |
|-----------|---------|------|
| probes recorded, `s_go` in window | H_CANDIDATE **falsified** under isolated TB | silicon `s_busy` / rst-seq / XPM recovery (not FIFO law) |
| probes recorded, empty never clears | H_RIVAL **supported** | FIFO write/rst |
| probes recorded, wr_en then no rd_en/pend/`s_go_r` | H_CANDIDATE **supported** | rd_en / pend / rst |
| compile fail | XSIM=FAIL | fix TB only |

CLASS stays **B** until silicon `s_go` proven. No EXISTENCE. No BOARD_PASS.
