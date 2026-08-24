# BOARD_MIG_R2_SWEEP — per-run deltas (metric_clear grid)

**Evidence_class:** BOARD_MIG — **not** Native V1 BOARD_PASS  
**Board:** Digilent Arty A7-100T `210319BE776EA` / UART COM12  
**Bit:** `c08ae8634fe2b4568de0eaeed5f6e750bd3ef2b7aad4e401467afac3c01957cc`  
**WNS:** +1.060 ns (`wns.txt` / post-route summary for this bit)  
**Marker:** `A7NG_MIG_BOARD_R2_OK`  
**Raw UART:** `board_uart_capture.uart.txt`

## Grid (16 cells, TOTAL=64 per cell)

stall_frac = pe_stall / (pe_stall + pe_busy), recomputed from raw UART hex fields.

| burst | out | stall_frac | axi_read_bytes | axi_read_bursts | axi_read_beats | data_mm | rresp | rlast | exp | rcv | cons | rid | r_bp | pe_stall | pe_busy |
|------:|----:|-----------:|---------------:|----------------:|---------------:|--------:|------:|------:|----:|----:|-----:|----:|-----:|---------:|--------:|
| 1 | 1 | 0.960248 | 1024 | 64 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 1546 | 64 |
| 1 | 2 | 0.920299 | 1024 | 64 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 739 | 64 |
| 1 | 4 | 0.855204 | 1024 | 64 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 378 | 64 |
| 1 | 8 | 0.751938 | 1024 | 64 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 194 | 64 |
| 4 | 1 | 0.858407 | 1024 | 16 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 388 | 64 |
| 4 | 2 | 0.761194 | 1024 | 16 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 204 | 64 |
| 4 | 4 | 0.619048 | 1024 | 16 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 104 | 64 |
| 4 | 8 | 0.555556 | 1024 | 16 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 15 | 0 | 80 | 64 |
| 8 | 1 | 0.759398 | 1024 | 8 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 7 | 0 | 202 | 64 |
| 8 | 2 | 0.659574 | 1024 | 8 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 7 | 0 | 124 | 64 |
| 8 | 4 | 0.555556 | 1024 | 8 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 7 | 0 | 80 | 64 |
| 8 | 8 | 0.609756 | 1024 | 8 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 7 | 0 | 100 | 64 |
| 16 | 1 | 0.636364 | 1024 | 4 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 3 | 0 | 112 | 64 |
| 16 | 2 | 0.552448 | 1024 | 4 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 3 | 0 | 79 | 64 |
| 16 | 4 | 0.609756 | 1024 | 4 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 3 | 0 | 100 | 64 |
| 16 | 8 | 0.555556 | 1024 | 4 | 64 | 0 | 0 | 0 | 64 | 64 | 64 | 3 | 0 | 80 | 64 |

UART burst field `10` = burst 16 (RTL decimal tens+ones print). No invented GB/s.

## CONTROL vs MIG-METRIC-00 XSim

| cell | silicon bytes/bursts/beats | XSim bytes/bursts/beats | integrity |
|------|---------------------------|-------------------------|-----------|
| (1,1) | 1024 / 64 / 64 | 1024 / 64 / 64 | CLEAN |
| (4,8) | 1024 / 16 / 64 | 1024 / 16 / 64 | CLEAN |

Quarantined pre-metric rows `(1,1) 0.923261` / `(4,8) 0.585366` remain superseded — not cited.
