# E2R F1q CLOSEOUT — E2R-TILE-DMA-REQ-PROBE-00

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-TILE-DMA-REQ-PROBE-00  
**Baseline:** F1p BIT_SHA `30EAF132AEF73629D0E74AB1D6382B8A659A8B8805C6C1B4A8A9AA990A01CAFF`

## ONE CHANGE

Expose `req_s[1]`, `dma_busy`, and `dma_owner` on UART after TILE_BST — sticky latch while CORE_BUSY, lines `TILE_REQ=H`, `TILE_DMA_BUSY=H`, `TILE_DMA_OWN=H`.

## GATE

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS (core) | 10.667 ns | **PASS** (≥0) |
| TNS (core) | 0 | **PASS** |
| WNS (ui) | 1.846 ns | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| DSP | 19 | note (not F1q gate) |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `708AC4D655DFF539F0DD89C393B802F40CFA0B2CBC35D670D84F66D469030276` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`TILE_DMA_REQ_PROBE_BIT_PROGRAM_PASS`) |

## UART markers (board, ~121s capture)

| Marker | Value | Decode |
|--------|-------|--------|
| TILE_MISS | **YES** | weight miss stuck |
| TILE_DST | **0** | `D_IDLE` |
| TILE_BST | **4** | `B_REQ` (bank waiting DMA ack) |
| TILE_REQ | **1** | `req_s[1]` asserted |
| TILE_DMA_BUSY | **1** | global DMA busy high |
| TILE_DMA_OWN | **0** | tile dst FSM still IDLE (owner=0) |
| W_STALL | **YES** | |
| PHASE | **01** | ST_EMB |
| CORE_BUSY | **YES** | |
| CORE_DONE | **NO** | |
| PRED_NZ | **NO** | |
| pred | **NO_PRED** | |
| LAST_STAGE | TILE_DMA_OWN=0 | |
| BYTES | 394 | |

### D_IDLE gate (weight_tile803k.sv ~287)

`if (req_s[1] && !dma_busy) dst <= D_GO;`

Observed: `req_s[1]=1`, `dma_busy=1`, `dma_owner=0`, `dst=D_IDLE` → **gate blocked by dma_busy**.

## Hypothesis verdict

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (`dma_busy` stuck high blocks D_IDLE→D_GO) | **SUPPORTED** — req_s[1]=1 but dma_busy=1 prevents transition |
| H_RIVAL (req_s pulse lost / never asserted) | **FALSIFIED** — TILE_REQ=1 |
| FALSIFIER (req=1 + dma_busy=0 yet dst stays IDLE) | **NOT MET** — dma_busy=1 |
| PROBE_PASS | **YES** — TILE_REQ/TILE_DMA_BUSY/TILE_DMA_OWN decode on UART |
| EXISTENCE_PASS | **NO** (pred≠664) |

## Artifacts

- `arty_a7_ng_native_v1_tile_dma_req_probe_00.bit`
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

**F1r** — trace why global `dma_busy` stays high while tile `dma_owner=0` (MIG/WDMA mux contention, prior transfer not completing, or spurious busy from query R-path).
