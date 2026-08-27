# E2R-T2-SPI-WMEM-00 PREREGISTER

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Gate:** E2R-T2-SPI-WMEM-00 → then E2R-BOARD-EXISTENCE-01

## ONE UNKNOWN
Can FPGA-owned T2-SPI (Arty QSPI → AXI → DDR @ 0x0010_0000, 802816 B) replace synth-zero `rd_img` so rebuilt bit + COM12 yields UART ASCII **pred=664**?

## Scientific frame
| Field | Value |
|-------|-------|
| OBSERVATION | synth rd_img zeros; Gate2 XSim uses $readmemh |
| H_CANDIDATE | QSPI image @ 0x400000 + SPI master → exact DDR_WBASE |
| H_RIVAL | flash layout / SPI stall / SHA mismatch / timing regress / F2 hex UART |
| FALSIFIER | DDR≠hex OR pred≠664 OR host poke used OR hex UART (pred=298) |
| UNIT | bytes/SHA ≠ clock cycle |
| CONTROL | hex SHA `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` |

## Same-patch F2 (CONFIRMED defect)
UART `"0"+pred[9:8]/[7:4]/[3:0]` printed hex nibbles → 664→298.  
**Fix:** decimal `/100 /10 %10` ASCII digits. Marker stays `NATIVE_V1_EXIST_ROW,pred=<decimal>`.

## B1
PLAUSIBLE only — not fixed this gate.

## Forbidden
SIM_FULL=1; host weight poke as PASS; invent T2-COMPRESS; self-claim full NATIVE_V1_MINI_AI_BOARD_PASS.
