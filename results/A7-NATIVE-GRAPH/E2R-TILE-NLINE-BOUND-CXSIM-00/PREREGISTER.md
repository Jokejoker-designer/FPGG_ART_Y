# E2R-TILE-NLINE-BOUND-CXSIM-00 — PREREGISTER

**Before UNIT run.** Do not edit after XSim.

| Field | Value |
|-------|-------|
| OBSERVATION | Chunk 1 then chunk 2 start on completable stub (CHUNK2_GO dest4_2 cyc=304 stall=1). Silicon ATOM1 dest=5 then 300 s no CORE_DONE. rg_nline: POS rg==1 → 128 else 1024. CHUNK2_GO miss OFF_POS + cur_rg_reset=0. Refill-time ~20 min is ENGINEERING_INFERENCE. |
| UNKNOWN | on this same miss, does one region refill reach stall=0, and how many dest=4 / dma_go bursts? |
| H_CANDIDATE | STALL_HOLD — timeout still stall=1 (nline never finishes on stub) |
| H_RIVAL | REGION_DONE — stall=0 and dest4_cnt == nline for this miss |
| FALSIFIER | stop at chunk 2; hold busy after first done; SIM_FULL=1; leftover grant; C-FIX; treat mid-refill stall=1 as stuck |
| UNIT | one miss, one region (not clock-as-query) |
| CONTROL | CHUNK2_GO dest4_2 at cyc=304 stall=1; rg_nline law |
| METRICS | dest4_cnt, dma_go bursts, dest-clk to stall=0, nline, bst at end |

Classes: REGION_DONE / STALL_HOLD / EARLY_IDLE / ACK_HOLD.  
Timeout cap: **1000000** dest-clk after reset release (≥1e6; 1024 chunks × ~300 dest-clk plus margin).  
Do not require stall=0 as a pass bit. Classify.  
nline from visible `nline_h` / `dbg_cur_rg` / hold_rg law; do not assume 1024 if measured otherwise.  
PROGRAM=NO. C-FIX=NONE. XSim ≠ board. Existence not claimed.  
Silicon time (nline × MIG ms/chunk) is ENGINEERING_INFERENCE only.
