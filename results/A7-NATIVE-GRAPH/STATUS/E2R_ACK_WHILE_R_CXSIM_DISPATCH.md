# E2R-ACK-WHILE-R-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-ACK-WHILE-R-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX. No LiteScope.**

Silicon ATOM1 dest=**5** (`D_ACK`) one core cycle after dest=4, pack still reports dma_st=5. `dma_st` CDC is FINDING (unsafe 3b).  
Tile: `D_WAITDONE → D_ACK` iff `dma_done || !dma_busy`.

## Scientific frame

- **OBSERVATION:** ATOM1 dest=5. STILLR dest stays 4 while in-R until complete. dma_st on ATOM is not class-grade.
- **UNKNOWN:** on the STILLR vehicle (busy/in-R through dest=4, then complete), does dest become 5 while still in-R?
- **H_CANDIDATE:** `ACK_WHILE_R` — dest=5 and in-R/busy in the same cycle (tile desync).
- **H_RIVAL:** `ACK_ONLY_AFTER_DONE` — dest=5 only after `s_done` or `!busy`. Silicon dest=5 means core saw done/idle; ATOM dma_st=5 is CDC.
- **FALSIFIER:** force dest; C-FIX; complete before dest=4; `soc_top`+MIG.
- **UNIT:** one query; dest vs in-R each core cycle from first dest=4 until dest=5 or timeout.
- **CONTROL:** STILLR SNAP_DONE0 SHA `4F71A710…`; ATOM0 dest=4 ATOM1 dest=5; tile law above.
- **METRICS:** dest, in-R, `dma_busy`, `s_done`, cycle of first dest=5 vs first done.

## Vehicle

Copy STILLR TB. Keep in-R through dest=4 then complete. **Do not** force dest=5. Print dest vs busy/done around dest=4/5. `SIM_FULL=0`.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ACK_WHILE_R` | some cycle dest=5 ∧ in-R/busy | none |
| `ACK_ONLY_AFTER_DONE` | dest=5 occurs and only after done/`!busy` | none |
| `FAIL_NO_ACK` | dest=5 never | none |
| `FAIL_NO_DESTWAIT` | dest=4 never | none |

Marker `E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS` only if ACK_WHILE_R or ACK_ONLY_AFTER_DONE.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
