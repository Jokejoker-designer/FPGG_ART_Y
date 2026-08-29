# E2R-SDONE-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-SDONE-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX. No LiteScope.**

ATOMIC-SGO ([76866d70](76866d70-bded-4f08-b56e-4fd25c57b822)): silicon dest=4 grant=1 leftover SET, sticky=1, own_ui=1, dma_st=5(R). Sequential `SDONE=0` `W_STALL` `PHASE=01`.  
MUX leftover TB **held** `busy=1` `done=0` after 8 R — that vehicle cannot answer done.

## Scientific frame

- **OBSERVATION:** Silicon SGO_HIT and DMA in R at dest=4. UART `SDONE=0`. Old MUX bag forced hold-busy.
- **UNKNOWN:** on dest=4 ∧ grant=1 ∧ leftover SET ∧ `s_go` fired, if the WDMA responder **completes** (deassert busy, pulse done after legal beats), does `s_done` / `dbg_s_done_sticky` rise?
- **H_CANDIDATE:** `SDONE_NEVER` — leftover SET keeps DMA in R; done never.
- **H_RIVAL:** `SDONE_ROSE` — done rises after complete beats. Silicon `SDONE=0` is stub≠board / still-in-R.
- **FALSIFIER:** hold `busy=1` after 8 R (old MUX); C-FIX; A2; `soc_top`+MIG; force dest.
- **UNIT:** one query; first dest=4 snapshot + whether done ever in that query.
- **CONTROL:** MUX hold-busy (done forced 0); ATOMIC-SGO dma_st=5; sequential `SDONE=0`.
- **METRICS:** dest, grant, leftover terms, `s_go` ever, `s_done` ever, `dbg_s_done_sticky`, dma FSM if present, busy at dest=4 and at end.

## Vehicle

Copy SGO-MUX / SGO-LATCH TB. **One change:** after 8 shared-stub R beats, pulse `s_done` and clear `s_busy` (completable responder). Keep `s_dma_idle` as CONTROL unless the responder idle bit must follow done (document). `SIM_FULL=0`. No `soc_top`. No MIG.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `SDONE_ROSE` | dest=4 reached; done/sticky=1 in that query | none |
| `SDONE_NEVER` | dest=4 reached; `s_go` fired; done never | none |
| `FAIL_NO_DESTWAIT` | never dest=4 | none |

Marker `E2R_SDONE_CXSIM_00_XSIM_PASS` only if ROSE or NEVER.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
