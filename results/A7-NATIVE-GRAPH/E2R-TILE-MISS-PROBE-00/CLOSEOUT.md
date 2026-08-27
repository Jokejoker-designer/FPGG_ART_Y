# E2R F1o CLOSEOUT — E2R-TILE-MISS-PROBE-00 RECAPTURE

**Date:** 2026-08-26  
**Agent:** a7-vivado-gate (F1o resume — program + UART only, no rebuild)  
**Gate:** E2R-TILE-MISS-PROBE-00

## Human note

If a future capture returns **0 bytes** after program, press the **RESET** button on the Arty A7 (or USB replug) and run a second 180s UART capture **without reprogramming**.

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `11E6B56C37214BAB9763350771A01546D92FC68C7C3C3C662262E470574FBF06` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`TILE_MISS_PROBE_BIT_PROGRAM_PASS`) |
| Rebuild | **NO** (prebuilt bit) |

## UART markers (board)

| Marker | Value |
|--------|-------|
| TILE_MISS | **YES** |
| TILE_DST | **0** |
| W_STALL | **YES** |
| PHASE | **01** (ST_EMB — embedding) |
| CORE_BUSY | **YES** |
| CORE_DONE | **NO** |
| PRED_NZ | **NO** |
| BIND | **NO** (BIND_BUSY=YES) |
| pred | **NO_PRED** |
| LAST_STAGE | TILE_DST=0 |
| BYTES | 341 |
| Capture duration | ~180s armed pre-program |

## Hypothesis verdict

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (tile miss → W_STALL) | **SUPPORTED** — TILE_MISS=YES, W_STALL=YES, TILE_DST=0 |
| H_RIVAL (UART silent = RTL regression) | **FALSIFIED** — 341 bytes on recapture without board RESET |
| Existence (`pred=664`) | **NO** |

## Artifacts

- `uart_capture.txt`
- `capture_stdout.log`
- `program_stdout.log`
- `e2r_metrics.txt`
- `arty_a7_ng_native_v1_tile_miss_probe_00.bit`

## NEXT

**F1p** — tile/DMA FSM probe (`TILE_MISS=YES`, `W_STALL=YES`, `PHASE=01`)
