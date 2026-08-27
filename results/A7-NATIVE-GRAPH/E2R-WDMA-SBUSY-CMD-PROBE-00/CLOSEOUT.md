# E2R-WDMA-SBUSY-CMD-PROBE-00 — CLOSEOUT (Class B)

**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-vivado-gate`  
**JTAG:** `210319BE776EA` (single target)  
**COM:** COM12 @115200 armed before program  
**EXISTENCE:** not claimed (`pred` absent)  
**BOARD_PASS:** not claimed

## Measured (post-route / board)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.692 ns | post-route `report_timing_summary.rpt` Design Timing Summary | PASS (≥0) |
| TNS | 0.000 ns | post-route same row | PASS (=0) |
| WHS | 0.009 ns | post-route same row | PASS |
| THS | 0.000 ns | post-route same row | PASS |
| core_WNS | 7.792 ns | post-route domain `core_clk` | PASS |
| ui_WNS | 1.788 ns | post-route domain `clk_pll_i` | PASS |
| BRAM36 | 103 | post-route cell count | PASS (≤135) |
| unsafe_cdc | 0 | `report_cdc.rpt` (mig benign falsepath=3) | PASS (=0) |
| BIT_SHA256 | `A9F529B2FAFC3FE6E8C79DA16F200508633356448CBC29B47CBFDE04FE1A91C0` | write_bitstream | — |
| F1w CONTROL | `4933B19BCC6C06603979896565E31DCD9703AFF7FD99EA8CD564DA0E659C25D6` | not overwritten | — |

## UART_BLOCK (board)

```
SGO=0
MGO=1
CMD_EMPTY=0
SBUSY_PEND=1
CMD_ST=2
CMD_RD=1
TILE_DST=4
```

FIRST_MISSING_MARKER=NONE. F1w tail kept (WDMA_OWNER=1 GRANT=0 RPATH_IDLE=0 W_STALL PHASE=01).

## Hypothesis vs UART (one boot)

| Claim | Status |
|-------|--------|
| H_RIVAL (`cmd_empty` stays 1 after MGO) | **FALSIFIED** — `CMD_EMPTY=0` |
| H_CANDIDATE (`s_busy` / `cmd_st≠IDLE` so `cmd_rd_en` never fires) | **FALSIFIED as stated** — `CMD_RD=1` |
| s_busy while pending | **observed** — `SBUSY_PEND=1` |
| cmd_st while pending | **observed** — `CMD_ST=2` (C_BUSY) |
| Gate FALSIFIER (`EMPTY=0` + `SBUSY_PEND=0` + `CMD_ST=0` + `SGO=0`) | **not met** |

CLASS=B. XSim ≠ board. No pred=664.

## NEXT_ONE_UNKNOWN

Why `SGO=0` after silicon `CMD_RD=1` — `s_go_r` never promoted, or F1u SGO latch (only while `core_busy`) missed a late pulse. Do not edit B1 / grant / r_path_idle / FIFO law from this bag.
