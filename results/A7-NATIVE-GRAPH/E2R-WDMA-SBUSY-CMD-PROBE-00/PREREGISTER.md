# E2R-WDMA-SBUSY-CMD-PROBE-00 — PREREGISTER (before UART)

**Gate:** E2R-WDMA-SBUSY-CMD-PROBE-00 (Class B2)  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-vivado-gate`  
**Unit:** one query boot; stickies around first MGO (not clocks)

## Frozen frame (pre-UART)

| Field | Value |
|-------|-------|
| OBSERVATION | F1w: MGO=1 SGO=0 SDMA_BUSY=0 (late latch). TB: DUT m_go→s_go in 8 s_clk when s_busy=0 |
| UNKNOWN | At silicon `m_go` / while cmd sits in FIFO: is `s_busy=1` or `cmd_st≠C_IDLE` so `cmd_rd_en` never fires? |
| H_CANDIDATE | `s_busy` high (or `cmd_st` not IDLE) when cmd pending → no `s_go`. Late `SDMA_BUSY=0` is after the window. |
| H_RIVAL | `cmd_empty` stays 1 on ui (write never crossed) despite MGO=1 |
| FALSIFIER | UART: `CMD_EMPTY=0` + `SBUSY_PEND=0` + `CMD_ST=0` but `SGO=0` → not this gate |
| CONTROL | F1w BIT `4933B19BCC6C06603979896565E31DCD9703AFF7FD99EA8CD564DA0E659C25D6` UART tail |
| ONE CHANGE | UART stickies only: `s_busy` while `!cmd_empty`, `cmd_st`, `cmd_empty` after MGO, `cmd_rd_en` sticky. Keep F1w lines. No B1 / grant / r_path_idle / FIFO law edit |

## Metrics (preregistered)

WNS ≥ 0 ns, TNS = 0, unsafe_cdc = 0, BRAM36 ≤ 135 (post-route).  
UART_BLOCK: SGO MGO CMD_EMPTY SBUSY_PEND CMD_ST CMD_RD TILE_DST.  
No EXISTENCE unless pred=664. No BOARD_PASS.
