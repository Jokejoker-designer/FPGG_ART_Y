# E2R-WDMA-BFIX-00-EXCL — PREREGISTER (before bitstream / UART)

**Gate:** E2R-WDMA-BFIX-00-EXCL (existence plan slot 1/3 after B2)  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-vivado-gate`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_BFIX_DISPATCH.md`  
**CONTROL:** B2 BIT `A9F529B2FAFC3FE6E8C79DA16F200508633356448CBC29B47CBFDE04FE1A91C0`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | B2 UART CMD_EMPTY=0 SBUSY_PEND=1 CMD_ST=2 CMD_RD=1 SGO=0 DMA_ST=0 TILE_DST=4 MGO=1 GRANT=0. Isolated TB: s_busy=1 gates cmd_rd_en. |
| UNKNOWN | ghost s_busy holds cmd FSM in C_BUSY so s_go cannot reach/re-issue ddr_tile_dma while dest=D_WAITDONE and dma IDLE. |
| H_CANDIDATE | nới cmd_rd_en and C_BUSY→C_IDLE when dest is D_GO or D_WAITDONE AND ddr_tile_dma IDLE, even if s_busy=1. |
| H_RIVAL | first s_go was lost only because GRANT=0 / r_path_idle; cmd FSM law change will not produce SGO (CLASS stays B). |
| FALSIFIER | after this one RTL, UART still MGO=1 SGO=0 (CLASS B) OR MGO=0 (CLASS A). |
| UNIT | one boot query |
| CONTROL | B2 BIT A9F529B2… UART tail |
| ONE CHANGE | `rtl/board/a7ng_wdma_cdc.sv` cmd path only + minimal soc_top dest/dma_idle port-wire. Keep F1s busy_hold. No B1 grant. No r_path_idle=1. No D_IDLE owner-gate. No new UART probes. |

## Numeric gates (post-route; STOP if fail, do not program)

WNS≥0 TNS=0 unsafe_cdc=0 BRAM≤135

## Classify (after exclusive program)

- A: MGO=0 → STOP
- B: MGO=1 SGO=0 → STOP (DECIDE, no B4 probe)
- C: MGO=1 SGO=1 GRANT=0 → report C
- EXISTENCE: pred=664 only (not BOARD_PASS)
- pred nonzero ≠664 → STOP, archive, do not change expected

## Functional chain (FIRST_MISSING_MARKER = first fail)

MGO=1 → SGO=1 → GRANT=1 → OWN_UI=1 → DMA_ST≠0 → SDONE → W_STALL=0 → CORE_DONE → pred=664
