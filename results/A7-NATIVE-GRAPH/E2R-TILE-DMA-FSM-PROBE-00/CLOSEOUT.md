# E2R F1p CLOSEOUT — E2R-TILE-DMA-FSM-PROBE-00

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-TILE-DMA-FSM-PROBE-00  
**Baseline:** F1o BIT_SHA `11E6B56C37214BAB9763350771A01546D92FC68C7C3C3C662262E470574FBF06`

## ONE CHANGE

Expose `weight_tile803k` bank FSM (`dbg_bst`) + DMA FSM (`dbg_dst`, already as TILE_DST) on UART after TILE_MISS — sticky latch while CORE_BUSY, new line `TILE_BST=H`.

## GATE

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS (core) | 9.971 ns | **PASS** (≥0) |
| TNS (core) | 0 | **PASS** |
| WNS (ui) | 2.754 ns | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| DSP | 19 | note (not F1p gate) |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `30EAF132AEF73629D0E74AB1D6382B8A659A8B8805C6C1B4A8A9AA990A01CAFF` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`TILE_DMA_FSM_PROBE_BIT_PROGRAM_PASS`) |

## UART markers (board, ~121s capture)

| Marker | Value | Decode |
|--------|-------|--------|
| TILE_MISS | **YES** | weight miss stuck |
| TILE_DMA_STATE (TILE_DST) | **0** | `D_IDLE` |
| dbg_bst (TILE_BST) | **4** | `B_REQ` (bank waiting DMA ack) |
| W_STALL | **YES** | |
| PHASE | **01** | ST_EMB |
| CORE_BUSY | **YES** | |
| CORE_DONE | **NO** | |
| PRED_NZ | **NO** | |
| pred | **NO_PRED** | |
| LAST_STAGE | TILE_BST=4 | |
| BYTES | 352 | |

### FSM decode (weight_tile803k.sv)

**Bank bst:** 0=IDLE 1=FILL 2=FWAIT 3=FCAP **4=REQ** 5=WAITACK 6=STORE 7=SWAIT 8=NEXT  
**DMA dst:** **0=IDLE** 1=GO 2=FEED 3=DRAIN 4=WAITDONE 5=ACK

## Hypothesis verdict

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (DMA FSM stuck on first fetch) | **PARTIAL** — bank at `B_REQ`, DMA at `D_IDLE`; req/ack path not completing |
| H_RIVAL (flash offset @ 0x400000) | **WEAK** — DMA never left IDLE; addr mismatch less likely than req→go stall |
| FALSIFIER (DMA progression or TILE_MISS=NO) | **NOT MET** — TILE_MISS=YES; DMA still IDLE |
| PROBE_PASS | **YES** — TILE_BST/TILE_DST decode on UART |
| EXISTENCE_PASS | **NO** (pred≠664) |

## Artifacts

- `arty_a7_ng_native_v1_tile_dma_fsm_probe_00.bit`
- `BIT_SHA256.txt`
- `uart_capture.txt`
- `capture_stdout.log`
- `program_stdout.log`
- `build_stdout.log`
- `e2r_metrics.txt`
- `report_timing_summary.rpt`
- `report_utilization_route_hier.rpt`
- `report_cdc.rpt`

## NEXT

**F1q** — tile DMA req/ack + `dma_busy` probe at first miss (`B_REQ` + `D_IDLE` → why `req` never promotes DMA to `D_GO`).
