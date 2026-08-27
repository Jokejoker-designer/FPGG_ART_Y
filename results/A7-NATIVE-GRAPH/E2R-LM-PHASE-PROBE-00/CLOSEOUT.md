# E2R F1n CLOSEOUT — E2R-LM-PHASE-PROBE-00

**Date:** 2026-08-26  
**Agent:** a7-vivado-gate (resume — program + UART only, no rebuild)  
**Gate:** E2R-LM-PHASE-PROBE-00

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `6EE273BB708833E3CDEA16365459645E2A0B6DCC244207FC3948CBA3F44E11A6` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`LM_PHASE_PROBE_BIT_PROGRAM_PASS`) |
| Rebuild | **NO** (prebuilt bit) |

## UART markers (board)

| Marker | Value |
|--------|-------|
| W_STALL | **YES** |
| PHASE | **01** (ST_EMB — embedding) |
| CORE_BUSY | **YES** |
| CORE_DONE | **NO** |
| PRED_NZ | **NO** |
| BIND | **NO** (BIND_BUSY=YES) |
| pred | **NO_PRED** |
| LAST_STAGE | PHASE=01 |
| BYTES | 320 |
| Capture duration | ~121s (early exit: CORE_BUSY + PHASE seen) |

## Hypothesis verdict

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (`W_STALL=YES` tile miss) | **SUPPORTED** — W_STALL=YES + PHASE=01 (early forward) |
| H_RIVAL (compute FSM stuck, no stall) | **FALSIFIED** |
| Existence (`pred=664`) | **NO** |

## Artifacts

- `uart_capture.txt`
- `bit_program.log`
- `capture_stdout.log`
- `program_stdout.log`
- `e2r_metrics.txt`

## NEXT

**F1o** — tile/DMA second-miss probe (`W_STALL=YES` + early phase per `E2R_F1N_PHASE_DECODE.md`)
