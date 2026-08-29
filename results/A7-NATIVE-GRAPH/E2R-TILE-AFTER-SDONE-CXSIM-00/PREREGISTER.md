# E2R-TILE-AFTER-SDONE-CXSIM-00 — PREREGISTER

**Before UNIT run.** Do not edit after XSim.

| Field | Value |
|-------|-------|
| OBSERVATION | REARM silicon dest=4→5, ATOM0=`0000059C` sdone sticky=1, hold 300 s, no CORE_DONE. UART TILE_BST=4 is first-seen B_REQ. stall=(bst!=B_IDLE)&#124;&#124;miss for whole refill. |
| UNKNOWN | after dma_done at D_WAITDONE, does bst leave B_REQ (first-chunk handshake)? |
| H_CANDIDATE | ACK_STUCK — dest=5, bst stays B_REQ |
| H_RIVAL | CHUNK_ACK — dest=5 and bst reaches B_WAITACK or B_STORE |
| FALSIFIER | leftover grant bags; SIM_FULL=1; hold busy after done; treat one-chunk stall=1 as stuck |
| UNIT | one tile miss, first DMA chunk |
| CONTROL | silicon ATOM dest 4→5; F1p dest=0∧B_REQ |
| METRICS | dbg_dst, dbg_bst, stall, dbg_req after dma_done |

Classes: CHUNK_ACK / ACK_STUCK / DEST_STUCK / NO_MISS. PROGRAM=NO. C-FIX=NONE.
