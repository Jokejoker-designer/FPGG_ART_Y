# E2R-WDMA-BFIX-00-EXCL — CLOSEOUT (CLASS B, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**JTAG:** `210319BE776EA` (single target)  
**COM12:** armed before program; capture `uart_capture.txt` (nonzero)

## Numeric gates (post-route `report_timing_summary.rpt`)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.616 ns | post-route Design Timing Summary | PASS (≥0) |
| TNS | 0.000 ns | post-route Design Timing Summary | PASS (=0) |
| WHS | 0.018 ns | post-route Design Timing Summary | PASS |
| THS | 0.000 ns | post-route Design Timing Summary | PASS |
| core_WNS | 10.318 ns | post-route clock table | PASS |
| ui_WNS | 2.351 ns | post-route `clk_pll_i` | PASS |
| BRAM | 103 | post-route util RAMB36 | PASS (≤135) |
| unsafe_cdc | 0 | `report_cdc.rpt` user_unsafe | PASS |
| DSP | 19 | post-route util | reported (not this gate) |

TCL `e2r_metrics.txt` WNS/TNS printed NA (regex miss); signoff numbers taken from the report file.

## Bit

BIT_SHA=`6023D9A340FD19056C736AB37408A05C31EFF44B1B12F6F0DEE84924969D28A1`  
CONTROL B2 BIT unchanged `A9F529B2FAFC3FE6E8C79DA16F200508633356448CBC29B47CBFDE04FE1A91C0`

## UART (one boot query)

```
TILE_DST=4 DMA_ST=0 SGO=0 MGO=1
CMD_EMPTY=0 SBUSY_PEND=1 CMD_ST=2 CMD_RD=1
WDMA_OWNER=1 WDMA_GRANT=0 RPATH_IDLE=0
WDMA_OWN_UI=0 SDONE=0 W_STALL
```

pred absent. Same CLASS B tail as B2 control.

## Classification

FIRST_MISSING_MARKER=SGO  
UART_BLOCK=MGO=1 SGO=0 GRANT=0 OWN_UI=0 DMA_ST=0 SDONE=0 W_STALL=1 CORE_DONE=0 pred=NO  
CLASS=B  
VERDICT=H_CANDIDATE falsified on this query (cmd-path nới did not produce SGO). H_RIVAL still live. STOP. No B4.  
NEXT_ONE_UNKNOWN=why SGO stays 0 after dest=D_WAITDONE + dma IDLE cmd-release (GRANT=0 / r_path_idle / ghost_busy_rel not live)  
EXISTENCE=not claimed  
BOARD_PASS=not claimed
