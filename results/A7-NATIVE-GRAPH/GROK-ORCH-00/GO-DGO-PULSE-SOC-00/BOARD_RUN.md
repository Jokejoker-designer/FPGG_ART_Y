# GO-DGO-PULSE-SOC-00 — board run 2026-08-30

**PROGRAM_DONE.** **EXISTENCE:** false (no pred=664). **BOARD_PASS:** not_claimed.

| Field | Value |
|-------|-------|
| Bit SHA256 | `125978D315B33E2F3E476919886B3DCA9868814F1F04E9C07D31D007A6B86072` |
| File timing | WNS=+0.359 TNS=0 (TIMING_PARSE -return_string NA is regex only) |
| JTAG | `210319BE776EA` (PYNQ `1234-tulA` listed, not opened) |
| startup | HIGH @ 11:36:41 |
| COM12 arm | 11:34:56 DTR/RTS false |
| UART last | `W_STALL` `PHASE=01` (`ST_EMB_POS`) — **no** `CORE_DONE` / exist row |
| 600 s close | `STOP_REASON=max_seconds` 600.109 s; 593 bytes, 65 lines; **PRED_LINES=NONE** |

## Contrast vs level-hold bit (`B64B2649`, pred=371)

| | Level-hold (371) | 1-cycle pulse (this) |
|--|------------------|----------------------|
| GRANT | 1 | **0** |
| OWNER | 0 | **1** |
| TILE_REQ | 0 | **1** |
| TILE_BST | 6 STORE | **4 REQ** |
| TILE_DMA_OWN | 0 | **1** |
| PHASE at UART | 07 ST_MV | **01 ST_EMB_POS** |
| CORE_DONE | yes | **not seen** |

Product `.go(dma_go && wdma_owner_ui)`: a 1-cycle `dma_go` while grant=0 **never reaches CDC**. Dest still enters `D_DRAIN`. Stub XSim3 still PASS (busy/r_valid immediate). Silicon waits `r_valid` forever.

Do not reprogram leftover LONGBOOT / `B64B2649` as a hang-fix.
