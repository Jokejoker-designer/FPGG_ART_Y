# PREREGISTER — E2R-LM-PHASE-PROBE-00 (F1n)

**Status:** SEALED BEFORE MEASUREMENT  
**Gate:** E2R-LM-PHASE-PROBE-00  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1N_DISPATCH.md`

## ONE UNKNOWN

After F1m shows `WDMA_DONE=YES` and `CORE_BUSY=YES`, is `tiny_gpt803k_core` frozen on `w_stall` (weight tile miss) or advancing to a stuck compute `phase`?

## Hypotheses

| Field | Value |
|-------|-------|
| H_CANDIDATE | `W_STALL=YES` after CORE_BUSY — weight tile refill hung mid-compute |
| H_RIVAL | `W_STALL=NO` but phase stuck in compute state (div/isqrt/FSM) |
| FALSIFIER | `W_STALL=NO` and phase shows IDLE/DONE |
| CONTROL | F1m UART baseline (`WDMA_DONE=YES`, `CORE_BUSY=YES`, no `CORE_DONE`) |
| METRICS | `W_STALL`, sticky `PHASE=HH`, `CORE_DONE`, `CORE_BUSY`, `PRED_NZ`, `BIND`, `pred` |

## Verdict classes

| Verdict | Rule |
|---------|------|
| H_CANDIDATE supported | `W_STALL=YES` + early phase (01–06) on UART |
| H_RIVAL supported | `W_STALL=NO` + stuck non-idle phase |
| Existence PASS | `pred=664` only |
| FAIL | No UART after program, or bit SHA mismatch |

## Success path (pre-registered)

- `W_STALL=YES` → F1o tile/DMA second-miss probe
- `W_STALL=NO` + `PHASE=xx` → F1o decode stuck state
