# WAITING_BOARD — mig_board_r2

**Detected:** 2026-08-22 ~14:49 (human: board bị tắt)

## What completed

| Step | Status | Evidence |
|------|--------|----------|
| Vivado impl (run 1) | **DONE** | `build/out/arty_a7_ng_mig_board_r2.bit` (3,826,004 B, 14:30:54) |
| WNS | **+1.142 ns** | `results/A7-NATIVE-GRAPH/MIG-BOARD-R2/wns.txt` |
| JTAG program | **DONE** | `program_mig_board_r2.log` → `210319BE776EA` at 14:31:44 |
| UART 4×4 grid | **NOT RUN** | `board_uart_capture.json`: `marker=false`, `rows=[]`, all 16 cells missing |
| Raw UART | **EMPTY** | `board_uart_capture.uart.txt` (0 bytes) |

## Interpretation

COM12 vẫn hiện trong Windows port list → USB cable có thể còn cắm, nhưng **FPGA không phản hồi UART**
(marker `A7NG_MIG_BOARD_ROW_OK` không xuất hiện). Khớp với board **mất nguồn** hoặc reset sau khi nạp bit.

A second Vivado run (`vivado_mig_board_r2_r2.log`) was in progress (re-route) when this note was written —
do not treat it as gate evidence until it completes and is explicitly selected.

## Quarantine status

**UNCHANGED.** Rows `0.923261 / 0.585366` remain quarantined until per-run silicon deltas exist.

## Resume procedure (human)

1. **Bật nguồn** Arty A7 (switch SW0 hoặc cắm USB power).
2. Giữ **USB-JTAG + USB-UART** (COM12).
3. Báo orchestrator **"board on"** → parent will:
   - Re-program `arty_a7_ng_mig_board_r2.bit` if JTAG target visible
   - Re-run UART capture only (16 cells, `metric_clear` between each)
   - **Not** restart full Vivado impl unless bit SHA mismatch

Gate stays **OPEN** / `WAITING_BOARD`. Not FAIL.
