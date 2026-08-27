# E2R-WDMA-CDC-BUSY-FIX-00 (F1s) — CLOSEOUT

**Agent:** a7-vivado-gate  
**Date:** 2026-08-27  
**RTL change:** `rtl/board/a7ng_wdma_cdc.sv` — `busy_hold` on m_clk; clear on `m_done`, set on `m_go`; `m_busy = busy_hold & m_busy_cdc`

## Vivado gate (post-route)

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS | 0.958 ns | PASS (≥0) |
| TNS | 0.000 ns | PASS (=0) |
| WHS | 0.020 ns | PASS |
| THS | 0.000 ns | PASS |
| core_WNS | 12.503 ns | PASS |
| ui_WNS | 1.842 ns | PASS |
| RAMB36 | 103 | PASS (≤135) |
| DSP | 19 | PASS (=0 gate N/A; design uses 19) |
| unsafe_cdc | 0 | PASS |
| gate_pass | 1 | PASS |

## Board

| Item | Value |
|------|-------|
| JTAG | 210319BE776EA (Arty A7-100T) |
| UART | COM12 @115200 |
| Program | WDMA_CDC_BUSY_FIX_BIT_PROGRAM_PASS |

## UART vs F1r baseline

| Signal | F1r baseline | F1s fix |
|--------|-------------|---------|
| TILE_DST | 0 (D_IDLE) | **4 (D_WAITDONE)** |
| TILE_REQ | 1 | 1 |
| SDMA_BUSY | 0 | 0 |
| WDMA_BUSY | 1 (ghost) | 1 |
| WDMA_OWN_UI | 0 | 0 |
| TILE_DMA_BUSY | 1 | 1 |
| TILE_DMA_OWN | 0 | **1** |
| W_STALL | YES | YES |
| pred | NO | NO |

## Verdict

- **FIX_PASS: NO** — WDMA_BUSY=1 at TILE_REQ (strict gate requires WDMA_BUSY=0 AND progress).
- **Functional progress:** TILE_DST advanced 0→4 (D_IDLE→D_WAITDONE); TILE_DMA_OWN=1. H_CANDIDATE partially supported — tile FSM unblocked past D_GO; may be in-flight legitimate busy during D_WAITDONE, not idle ghost.
- **EXISTENCE_PASS: NO** — no pred line.

## NEXT

F1t: probe whether WDMA_BUSY=1 is legitimate in-flight (D_WAITDONE) vs residual CDC ghost; check `m_done` / `s_done` handshake and W_STALL root cause. If stuck in D_WAITDONE without pred, trace `s_done`→`m_done`→`busy_hold` clear.
