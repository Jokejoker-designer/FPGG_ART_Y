# E2R F1t CLOSEOUT — E2R-TILE-DMA-DONE-PROBE-00

**Agent:** a7-vivado-gate  
**Date:** 2026-08-27  
**RTL change (probe only):** `a7ng_wdma_cdc.sv` sticky `s_done`/`m_done` + `busy_hold` dbg ports; `soc_top` UART lines `SDONE=` / `MDONE=` / `BUSY_HOLD=` latched at `core_busy`.

## Vivado gate (post-route)

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS | 0.962 ns | PASS (≥0) |
| TNS | 0.000 ns | PASS (=0) |
| WHS | 0.019 ns | PASS |
| THS | 0.000 ns | PASS |
| core_WNS | 11.020 ns | PASS |
| ui_WNS | 2.453 ns | PASS |
| RAMB36 | 103 | PASS (≤135) |
| DSP | 19 | informational |
| unsafe_cdc | 0 | PASS |
| gate_pass | 1 | PASS |

## Board

| Item | Value |
|------|-------|
| JTAG | 210319BE776EA (Arty A7-100T) |
| UART | COM12 @115200 (listed; **0 bytes received**) |
| Program | TILE_DMA_DONE_PROBE_BIT_PROGRAM_PASS |

## UART capture

| Attempt | Duration | Bytes | Notes |
|---------|----------|-------|-------|
| capture_uart_hb.py | 180 s | 0 | post-program immediate (prior session) |
| smoke (F1t reprogram) | 30 s | 0 | after program |
| smoke (F1s baseline reprogram) | 45 s | 0 | confirms UART path dead, not F1t-only |
| reprogram + 90 s wait + 90 s read | 180 s | 0 | MIG settle delay included |
| **F1t-RECAPTURE-1** (armed pre-program) | 121 s | **~900** | `uart_capture_recapture1.txt` — full boot+probe tail |

### F1t-RECAPTURE-1 decoded (board, COM12 @115200)

| Field | Value |
|-------|-------|
| SDONE | 0 |
| MDONE | 1 |
| BUSY_HOLD | 1 |
| TILE_DST | 4 |
| SDMA_BUSY | 0 |
| WDMA_BUSY | 1 |
| TILE_DMA_OWN | 1 |
| TILE_MISS | YES |
| W_STALL | YES |
| PHASE | 01 |
| pred | absent |
| PROBE_PASS | **YES** |
| EXISTENCE_PASS | **NO** (pred ≠ 664) |

## F1s baseline (control)

BIT_SHA: `FA82A8217E40C77E06411DB334409A5FBC90F2402FB66F615817DA1FC69ED5D8`  
UART tail: `TILE_DST=4 SDMA_BUSY=0 WDMA_BUSY=1 TILE_DMA_OWN=1 W_STALL PHASE=01`  
F1s had no SDONE/MDONE/BUSY_HOLD lines (pre-F1t probe).

## Verdict

- **PROBE_PASS: YES** — SDONE/MDONE/BUSY_HOLD decoded on F1t-RECAPTURE-1.
- **EXISTENCE_PASS: NO** — pred absent (no `pred=664`).
- **Interpretation:** `SDONE=0 MDONE=1 BUSY_HOLD=1` at `TILE_DST=4` → **H_RIVAL** (ddr_tile_dma `s_done` never asserted; CDC `m_done` latched high while source-side done sticky is 0).

## NEXT

1. F1u: investigate why `s_done` stays 0 while `m_done=1` and `BUSY_HOLD=1` at TILE_DST=4.
2. Compare against F1s baseline (no sticky probes) — F1t adds `SDONE=0 MDONE=1 BUSY_HOLD=1` on top of same TILE_DST=4 stall pattern.
3. No EXISTENCE_PASS until `pred=664`.
