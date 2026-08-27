# E2R F1r CLOSEOUT — E2R-TILE-DMA-BUSY-SRC-PROBE-00

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-TILE-DMA-BUSY-SRC-PROBE-00  
**Baseline:** F1q BIT_SHA `708AC4D655DFF539F0DD89C393B802F40CFA0B2CBC35D670D84F66D469030276`

## ONE CHANGE

Expose `s_dma_busy` (ui), `wdma_busy` (core), `wdma_owner_ui` on UART after TILE_REQ — latched while CORE_BUSY.

## GATE

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS (core) | 9.768 ns | **PASS** (≥0) |
| TNS (core) | 0 | **PASS** |
| WNS (ui) | 2.607 ns | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| DSP | 19 | note |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `25E5115D5F4E41F4BAFC602564BC3D7FE553C363825205A568BFABB8E143BCB0` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`TILE_DMA_BUSY_SRC_PROBE_BIT_PROGRAM_PASS`) |

## UART markers (board, ~121s capture)

| Marker | Value | Decode |
|--------|-------|--------|
| TILE_MISS | **YES** | weight miss stuck |
| TILE_DST | **0** | `D_IDLE` |
| TILE_BST | **4** | `B_REQ` |
| TILE_REQ | **1** | `req_s[1]` asserted |
| **SDMA_BUSY** | **0** | `ddr_tile_dma.s_dma_busy` clear on ui_clk |
| **WDMA_BUSY** | **1** | `a7ng_wdma_cdc.m_busy` stuck high on core_clk |
| **WDMA_OWN_UI** | **0** | MIG mux not owned by WDMA |
| TILE_DMA_BUSY | **1** | tile sees global busy (= wdma_busy) |
| TILE_DMA_OWN | **0** | tile dst FSM owner=0 |
| W_STALL | **YES** | |
| PHASE | **01** | ST_EMB |
| pred | **NO_PRED** | |
| PROBE_PASS | **YES** | |
| EXISTENCE_PASS | **NO** (pred≠664) |

## Hypothesis verdict

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (`s_dma_busy` stuck on ui_clk) | **FALSIFIED** — SDMA_BUSY=0 |
| H_RIVAL (WDMA CDC `m_busy` sticky after done) | **SUPPORTED** — WDMA_BUSY=1 while SDMA_BUSY=0 and WDMA_OWN_UI=0 |
| FALSIFIER (s_dma_busy=0 but wdma_busy=1) | **MET** → CDC-layer ghost busy, not ddr_tile_dma |

## Artifacts

- `arty_a7_ng_native_v1_tile_dma_busy_src_probe_00.bit`
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

**F1s** — fix or gate `a7ng_wdma_cdc.m_busy` deassert after `m_done`; tile `dma_busy` should track `s_dma_busy` or `wdma_busy && wdma_owner_ui` per LM06 reference.
