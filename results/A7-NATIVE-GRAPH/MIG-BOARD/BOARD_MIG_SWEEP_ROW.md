# BOARD_MIG_SWEEP_ROW — Digilent AXI MIG silicon (Arty A7-100T)

**Evidence_class:** BOARD_MIG (Digilent AXI MIG + ddr_feed on silicon) — **not** Native V1 BOARD_PASS, **not** HS-02  
**Date:** 2026-08-22  
**Law id:** `a7ng-mig-board-v0`  
**Board:** Digilent Arty A7-100T serial `210319BE776EA` (JTAG) / UART COM12  
**Bit SHA256:** `EF94BA6B7D7D2ABF3B2E7EFAC965F78AD565E7300657E948062494D7008B2EF1`  
**Marker:** `A7NG_MIG_BOARD_ROW_OK`  
**Raw UART:** `board_uart_capture.uart.txt` / `board_uart_capture.json`  
**WNS:** +1.068 ns (HS-12 met)  
**mig.prj:** PortInterface=AXI; SHA `870FA6EE…52190D` MATCH; app_*=0; hand_edit=NO

## Preregistered cells (UNIT = sweep cell; TOTAL=64; N_PE=16)

| burst | out | stall_frac | recs_per_cyc | pe_stall | pe_busy | cycles | cons | drop | ddr_rd_bytes | ddr_bursts |
|------:|----:|-----------:|-------------:|---------:|--------:|-------:|-----:|-----:|-------------:|-----------:|
| 1 | 1 | 0.923261 | 0.076739 | 770 | 64 | 834 | 64 | 0 | 1024 | 64 |
| 4 | 8 | 0.585366 | 0.414634 | 96 | 68 | 164 | 68 | 0 | 2112 | 81 |

stall_frac = pe_stall / (pe_stall + pe_busy). Host derives from integer UART fields — **no invent GB/s**.

## vs CONTROL (MIG_XSIM MIG-RIVAL)

| Cell | MIG_XSIM stall | BOARD stall | Delta (BOARD−XSim) |
|------|---------------:|------------:|-------------------:|
| (1,1) | 0.958710 | 0.923261 | −0.035449 |
| (4,8) | 0.549296 | 0.585366 | +0.036070 |

Stall cut with burst/outstanding is **supported** on silicon. Numbers differ from XSim (expected; HS-19).

## LIMIT notes

- `cons=68` on (4,8) exceeds TOTAL=64 (AR 1-cycle pipe + PE edge) — telemetry LIMIT, DROP still 0.
- First capture (`board_uart_capture_r1_sticky_done.*`) had invalid (4,8) zeros due to sticky `done` — superseded by this row after FSM CLR fix.

## H_RIVAL (this gate)

"XSim sold as board; invent bandwidth" — **did not fire**. Silicon UART rows archived; no GB/s invented.
