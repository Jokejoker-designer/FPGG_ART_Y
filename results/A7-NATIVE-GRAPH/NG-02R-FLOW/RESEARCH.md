# NG-02R-FLOW — research note

**Gate:** `ng02r_flow`  
**One unknown:** lossless Top-8→frontier push under concurrent 16-lane batch pressure.

## Options

| # | Approach | Verdict |
|---|----------|---------|
| 1 | Gate `topk_fire` with `!pushing` only | Incomplete — scorer pipe can still present a second batch mid-push |
| 2 | FSM + input handshake + `batch_ready_o` + frontier `ready_o` stall | **SELECTED** |
| 3 | Deep skid of multiple Top-8 results | Deferred — not required for single in-flight law |

## Selected law

One accepted 16-lane batch occupies the core until all 8 winners are frontier-accepted (or intentionally overflow-flagged). New `lane_valid` while busy is gated off at the scorer input.

## Hard stop results

Archived in `xsim_flow.log`: DROP=DUP=REORDER=CONS_FAIL=0 over ≥100_000 cycles.
