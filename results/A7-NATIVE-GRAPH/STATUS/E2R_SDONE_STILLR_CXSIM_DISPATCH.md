# E2R-SDONE-STILLR-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-SDONE-STILLR-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX. No LiteScope.**

SDONE-CXSIM ([141af702](141af702-88f7-4f09-85d0-29573b1a2bf5)) **SDONE_ROSE**: first burst **finished before** dest=4.  
Silicon ATOMIC-SGO dest=4 **dma_st=5(R)**. Occupancies differ. Sequential `SDONE=0` unanswered.

## Scientific frame

- **OBSERVATION:** Silicon dest=4 still-in-R. Stub ROSE only after a burst that completed before dest=4.
- **UNKNOWN:** at first dest=4 ∧ grant=1 ∧ leftover SET, if the responder is still busy/in-R (then completes later), is `dbg_s_done_sticky` 0 or 1?
- **H_CANDIDATE:** `SNAP_DONE0` — sticky=0 at dest=4 while in-R. Silicon `SDONE=0` can be same-cycle still-in-R.
- **H_RIVAL:** `SNAP_DONE1` — sticky=1 at dest=4 even while current burst in-R (prior done).
- **FALSIFIER:** complete before dest=4 (ROSE bag); hold busy forever (MUX); C-FIX; force dest; `soc_top`+MIG.
- **UNIT:** one query; first dest=4 snap; after-complete sticky is a secondary metric, not a second unknown.
- **CONTROL:** SDONE-CXSIM ROSE SHA `DF55ACF4…`; ATOMIC-SGO dma_st=5; sequential `SDONE=0`.
- **METRICS:** dest, leftover, in-R/busy at snap, `s_go` ever, sticky at dest=4, sticky after later complete.

## Vehicle

Copy `E2R-SDONE-CXSIM-00` TB. **One change:** do **not** pulse `s_done` / clear busy until **after** first dest=4 is latched (keep in-R through that snap), then complete the burst. `SIM_FULL=0`. No `soc_top`.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `SNAP_DONE0` | dest=4 + in-R/busy + sticky=0 | none |
| `SNAP_DONE1` | dest=4 + in-R/busy + sticky=1 | none |
| `FAIL_NOT_IN_R` | dest=4 but not in-R (vehicle miss) | none |
| `FAIL_NO_DESTWAIT` | never dest=4 | none |

Marker `E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS` only if SNAP_DONE0 or SNAP_DONE1.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.
