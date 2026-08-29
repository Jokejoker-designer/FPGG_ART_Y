# E2R-TILE-TOK-NLINE-CXSIM-00 — PREREGISTER

**Before UNIT run.** Do not edit after XSim.

| Field | Value |
|-------|-------|
| OBSERVATION | THRASH_NEXT dest4 128→129. POS REGION_DONE nline=128. `rg_nline` says TOK=1024. TOK nline not measured on this vehicle. |
| UNKNOWN | after the TOK switch, does that refill reach `stall=0` with dest4 increment = 1024? |
| H_CANDIDATE | TOK_DONE — `stall=0` and dest4 increment after switch == 1024 |
| H_RIVAL | TOK_HOLD — timeout still `stall=1` |
| FALSIFIER | stop at first dest=4 after switch; `SIM_FULL=1`; hold busy; C-FIX |
| UNIT | one TOK refill after one POS refill (not 2048 switches; not clock-as-query) |
| CONTROL | THRASH_NEXT dest4_post=36628 dest4=129; `rg_nline(0)=1024` |
| METRICS | dest4 increment after switch, stall_end, nline, bst |

Classes: TOK_DONE / TOK_HOLD / EARLY_IDLE / NO_THRASH.  
Copy THRASH-NEXT TB. **One change:** do not stop at first dest=4 after switch. Watch until `stall=0` again **or** timeout **≥2000000** dest-clk after switch.  
Completable stub every `dma_go`. `SIM_FULL=0`. PROGRAM=NO. C-FIX=NONE. XSim ≠ board.  
Existence not claimed. 1.18e6 DMA stays ENGINEERING_INFERENCE (n=1 TOK refill).
