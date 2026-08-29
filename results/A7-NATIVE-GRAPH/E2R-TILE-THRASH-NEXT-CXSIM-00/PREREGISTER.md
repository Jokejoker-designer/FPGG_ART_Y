# E2R-TILE-THRASH-NEXT-CXSIM-00 — PREREGISTER

**Before UNIT run.** Do not edit after XSim.

| Field | Value |
|-------|-------|
| OBSERVATION | One POS miss completes on stub (REGION_DONE dest4_cnt=128 stall=0 cur_rg=1). ST_EMB alternates TOK/POS. Law: `need_a = (rg_of(addr_a) != cur_rg)`. ~1.18e6 DMA is ENGINEERING_INFERENCE until a TOK/POS switch starts a new refill. |
| UNKNOWN | after first POS `stall=0`, does `addr_a` in TOK (`rg=0`) start a second dest=4 train? |
| H_CANDIDATE | THRASH_NEXT — new dest=4 / `dma_go` after the switch |
| H_RIVAL | HIT_HOLD — `stall` stays 0; no second dest=4 |
| FALSIFIER | switch before first `stall=0`; `SIM_FULL=1`; hold busy; C-FIX; stop at first region |
| UNIT | one POS refill then one TOK address (not 2048 switches; not clock-as-query) |
| CONTROL | REGION_DONE dest4_cnt=128 stall=0; `rg_of(<OFF_POS)=0` |
| METRICS | dest4 after switch, miss, cur_rg, stall, dma_go bursts |

Classes: THRASH_NEXT / HIT_HOLD / NO_DONE / ACK_HOLD.  
After first `stall=0`, set `addr_a=OFF_TOK` (0). Watch for a **new** dest=4 or timeout **≥500000** dest-clk after switch. Do not require TOK region to finish.  
Completable stub every `dma_go`. `SIM_FULL=0`. PROGRAM=NO. C-FIX=NONE. XSim ≠ board.  
Existence not claimed. 1.18e6 DMA stays ENGINEERING_INFERENCE (n=1 switch).
