# E2R-TILE-THRASH-NEXT-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-TILE-THRASH-NEXT-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [REGION_DONE](8276b8cf-e79d-498d-b46e-9b0afd494f4b) POS nline=128 `stall=0`. [OSC_2ND](7ef152e0-0472-4017-a123-e2790e686e23) 2048 TOK↔POS `waddr` sets. `need_a = (rg_of(addr_a) != cur_rg)`. ~1.18e6 DMA is ENGINEERING_INFERENCE until a TOK/POS switch is shown to start a **new** refill.

`--dispatch` next=`graph_late_materialize_00` is DEFERRED. This is existence side-lane.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | One POS miss completes on stub. ST_EMB alternates TOK/POS every dim. Law: miss when `rg_of(addr_a) != cur_rg`. |
| UNKNOWN | after first POS `stall=0`, does `addr_a` in TOK (`rg=0`) start a second dest=4 train? |
| H_CANDIDATE | `THRASH_NEXT` — new dest=4 / `dma_go` after the switch |
| H_RIVAL | `HIT_HOLD` — `stall` stays 0; no second dest=4 |
| FALSIFIER | switch before first `stall=0`; `SIM_FULL=1`; hold busy; C-FIX; stop at first region |
| UNIT | one POS refill then one TOK address (not 2048 switches; not clock-as-query) |
| CONTROL | REGION_DONE dest4_cnt=128 stall=0; `rg_of(<OFF_POS)=0` |
| METRICS | dest4_cnt after switch, miss, cur_rg, stall, dma_go bursts |

Copy NLINE-BOUND TB. **One change:** after first `stall=0`, set `addr_a` to TOK (`OFF_TOK` / 0). Completable stub every `dma_go`. Watch for a **new** dest=4 (or timeout ≥500_000 dest-clk after switch). Do not require the TOK region to finish.

| Class | Meaning |
|-------|---------|
| `THRASH_NEXT` | after switch, dest=4 again (new miss) |
| `HIT_HOLD` | first `stall=0` then no new dest=4 / miss stays 0 |
| `NO_DONE` | never first `stall=0` |
| `ACK_HOLD` | dest stays 5 |

Marker `E2R_TILE_THRASH_NEXT_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. 1.18e6 DMA stays ENGINEERING_INFERENCE even if THRASH_NEXT (n=1 switch).
