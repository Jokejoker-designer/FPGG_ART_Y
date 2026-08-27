# PREREGISTER — E2-BOARD-EXISTENCE-00

**Status:** SEALED BEFORE RUN  
**Gate:** `native_v1_existence_board_parallel_00`  
**Owner:** a7-vivado-gate (board lane)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Branch:** `native-v1-board-lane-stage0`  
**Evidence class:** `BOARD_UART_EXISTENCE` (narrow — not `NATIVE_V1_MINI_AI_BOARD_PASS`)

## Authorization

- `results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/ALLOW_PROGRAM_GROK.md`
- JTAG: `210319BE776E` / COM12 @115200

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Stage A XSim PASS pred=664; E1 BRAM 96; CLOCK80 WNS +3.648 ns @ 12.5 MHz OOC |
| UNKNOWN | On programmed Arty, does Native evidence drive actual LM06 and FPGA-owned pred with host_next_token=0, teacher=0? |
| H_CANDIDATE | Board SoC reproduces pred=664 on silicon with freeze=1 counters clean |
| H_RIVAL | Host leak; LM06 inactive; in-SoC timing fail; MIG stall |
| FALSIFIER | pred≠664 OR host counters nonzero OR LM06 inactive |
| UNIT | one board query episode |
| CONTROL | Stage A marker; E1 DCP SHA `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |
| METRICS | pred, actual_lm06_active, host_next_token, teacher_api_calls, fpga_next_token_valid, raw UART |

## Build contract

| Item | Value |
|------|--------|
| Top | `arty_a7_ng_native_v1_ab_soc_top` |
| Core | `a7ng_native_v1_ab_core` inside SoC |
| E1 lineage DCP | `E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_route.dcp` |
| Build dir | `build/native_v1_board_parallel_e2/` |
| Bit | `build/out/arty_a7_ng_native_v1_existence_00.bit` |
| Archive | `results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/` |

## Pass criteria (narrow)

- Bitstream programs pinned JTAG target
- MIG calib completes
- UART shows pred=664 (or honest FAIL with raw log)
- host_next_token=0, teacher=0, learn=0, freeze=1 during response window
- actual_lm06_active=1, fpga_next_token_valid>0

## Forbidden

- `NATIVE_V1_MINI_AI_BOARD_PASS` self-claim
- Edit main R6 worktree
- Overwrite frozen LM/EAM bits

**Date:** 2026-08-25
