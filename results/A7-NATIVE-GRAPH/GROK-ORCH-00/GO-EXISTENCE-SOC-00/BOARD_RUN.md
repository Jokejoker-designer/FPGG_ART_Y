# GO-EXISTENCE-SOC-00 — board run 2026-08-30

**PROGRAM_DONE.** **EXISTENCE:** false (UART pred≠664). **BOARD_PASS:** not_claimed.

| Field | Value |
|-------|-------|
| Human token | Cursor xong → arm COM12 |
| JTAG | `210319BE776EA` (one target, xc7a100t) |
| startup | HIGH |
| Bit SHA256 | `B64B26498F960980903FD4D7CF305FD4861996EBC60307901B32F89454870F17` |
| COM12 arm | 10:21:57+07 DTR/RTS false |
| Program | 10:22:48+07 `GO_EXISTENCE_SOC_00_PROGRAM_DONE` |
| UART row | `NATIVE_V1_EXIST_ROW,pred=371` |
| XSim vehicle | `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` (SIM_FULL=1, not this bit) |

XSim ≠ board. 371 is observed silicon. Existence gate remains exact `pred=664`.

## 600 s listen close

`STOP_REASON=max_seconds` elapsed 600.297 s. UART_BYTES=645, 69 lines.  
PRED_LINES only `NATIVE_V1_EXIST_ROW,pred=371`. No second row, no `pred=664`.
