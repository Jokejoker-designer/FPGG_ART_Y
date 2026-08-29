# E2R-TILE-NLINE-BOUND-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-TILE-NLINE-BOUND-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [CHUNK2_GO](134bd536-47ca-4298-a206-790edddcbc2b) / audit [CLEAN](9e3a93af-5cdc-430d-b871-ffbcb366634d): dest leaves `D_ACK`, second dest=4. `ACK_HOLD` falsified on stub. Silicon ATOM1 dest=5 + REARM 300 s `STILL_STALL` + LONG SILENT remain a different unknown.

`rg_nline`: POS `rg==1` → 128 chunks; else 1024. CHUNK2_GO miss was `OFF_POS` with `cur_rg_reset=0` → expected **1024** unless the run shows otherwise. Do not require `stall=0` as a pass bit; **classify**.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Chunk 1 then chunk 2 start on completable stub. Silicon first-chunk SDONE then 300 s no `CORE_DONE`. Refill-time ~20 min is ENGINEERING_INFERENCE (nline × assumed MIG ms/chunk). |
| UNKNOWN | on this same miss, does one region refill reach `stall=0`, and how many dest=4 / `dma_go` bursts is that? |
| H_CANDIDATE | `STALL_HOLD` — timeout still `stall=1` (nline never finishes on stub) |
| H_RIVAL | `REGION_DONE` — `stall=0` after dest4 count matches `rg_nline` |
| FALSIFIER | stop at chunk 2; hold busy after first done; `SIM_FULL=1`; leftover grant; C-FIX; treat `stall=1` mid-refill as stuck |
| UNIT | one miss, one region (not clock-as-query) |
| CONTROL | CHUNK2_GO dest4_2 at cyc=304 stall=1; `rg_nline` law |
| METRICS | dest4_cnt, dma_go bursts, dest-clk to stall=0, nline, bst at end |

Copy the CHUNK2_GO TB. **One change:** do not stop at second dest=4. Completable stub for **every** `dma_go`. Watch until `stall=0` **or** timeout (preregister ≥1e6 dest-clk; document). Count rising dest==4 events and `dma_go` bursts. Do not require `stall=0` for the marker.

| Class | Meaning |
|-------|---------|
| `REGION_DONE` | `stall=0` and dest4_cnt == nline for this miss |
| `STALL_HOLD` | timeout, `stall=1` |
| `EARLY_IDLE` | `stall=0` before dest4_cnt reaches nline |
| `ACK_HOLD` | dest stays 5; no further dest=4 |

Marker `E2R_TILE_NLINE_BOUND_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. Silicon time bound from this bag is ENGINEERING_INFERENCE only (stub ≠ MIG).
