# E2R-TILE-TOK-NLINE-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-TILE-TOK-NLINE-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [THRASH_NEXT](4f882908-ac36-4674-973b-12a236d0292e) / audit [CLEAN](e087589f-46b3-4df3-a3e9-4c578307f56c): POS `stall=0` dest4=128 then TOK `addr_a=0` started dest=4 again. POS nline **measured** 128. TOK nline is `rg_nline(0)=1024` in RTL — **not yet measured** on this vehicle.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | THRASH_NEXT dest4 128→129. POS REGION_DONE nline=128. `rg_nline` says TOK=1024. |
| UNKNOWN | after the TOK switch, does that refill reach `stall=0` with dest4 increment = 1024? |
| H_CANDIDATE | `TOK_DONE` — `stall=0` and dest4_after_switch increment == 1024 |
| H_RIVAL | `TOK_HOLD` — timeout still `stall=1` |
| FALSIFIER | stop at first dest=4 after switch; `SIM_FULL=1`; hold busy; C-FIX |
| UNIT | one TOK refill after one POS refill (not 2048 switches) |
| CONTROL | THRASH_NEXT dest4_post=36628 dest4=129; `rg_nline(0)=1024` |
| METRICS | dest4 increment after switch, stall_end, nline, bst |

Copy THRASH-NEXT TB. **One change:** do not stop at first dest=4 after switch. Completable stub every `dma_go`. Watch until `stall=0` again **or** timeout ≥2_000_000 dest-clk after switch.

| Class | Meaning |
|-------|---------|
| `TOK_DONE` | second `stall=0` and dest4 increment == 1024 |
| `TOK_HOLD` | timeout, `stall=1` |
| `EARLY_IDLE` | second `stall=0` but increment ≠ 1024 |
| `NO_THRASH` | never dest=4 after switch |

Marker `E2R_TILE_TOK_NLINE_CXSIM_00_XSIM_PASS` if classified. Existence not claimed.
