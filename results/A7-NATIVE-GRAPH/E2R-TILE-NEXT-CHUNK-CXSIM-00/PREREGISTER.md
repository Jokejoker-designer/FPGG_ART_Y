# E2R-TILE-NEXT-CHUNK-CXSIM-00 — PREREGISTER

**Before UNIT run.** Do not edit after XSim.

| Field | Value |
|-------|-------|
| OBSERVATION | First-chunk handshake works on stub (CHUNK_ACK dest=5 bst=5). Silicon ATOM1 dest=5 then 300 s silence. D_ACK exits only when !req_s[1]. nline>1 so stall stays 1 until B_IDLE. LONG listen SILENT. |
| UNKNOWN | after first D_ACK, does dest return D_IDLE and reach D_WAITDONE again (chunk 2 dma_go)? |
| H_CANDIDATE | ACK_HOLD — dest stays 5; no second dma_go |
| H_RIVAL | CHUNK2_GO — dest returns 0 then 4 again |
| FALSIFIER | stop at first dest=5; hold busy after first done; SIM_FULL=1; leftover grant; C-FIX |
| UNIT | one miss, chunk1 then chunk2 (not clock-as-query) |
| CONTROL | CHUNK_ACK dest=5 bst=5; silicon ATOM1 dest=5 |
| METRICS | dest after ACK, second dma_go, second dest=4, bst |

Classes: CHUNK2_GO / ACK_HOLD / IDLE_NO_GO / NO_ACK.  
Timeout cap: 20000 dest-clk after reset release. Do not require stall=0.  
PROGRAM=NO. C-FIX=NONE. XSim ≠ board. Existence not claimed.
