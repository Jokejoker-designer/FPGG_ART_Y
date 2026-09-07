# ACCEPTANCE — U6Q (qa-only)

```text
VERDICT   = PASS
OVERCLAIM = false
FRAUD     = false
SCOPE     = POST_ROUTE_OOC of a7ng_u6_typeclass_ooc_top @ 10 ns
```

## Checks

- `report_timing_route.rpt` Design Timing Summary: WNS=0.163 TNS=0.000
  WHS=0.132; "All user specified timing constraints are met."
- Setup failing endpoints = 0. Hold failing endpoints = 0.
- DSP = 0 in `report_utilization_route.rpt`.
- I/O false-path is declared in `build_ooc_impl.tcl` (same as U6T).
  Claim is internal R-to-R, not pad timing.
- HD.CLK_SRC unset is recorded, not hidden.
- Law `qse-v1-lexicon-hdc-00` first-hit/min-id unchanged in RTL.
- `beats()` not edited.
- BIT=NO PROGRAM=NO. Frozen `1F0F2ABB` not seated.
- U3Q / U6 XSim markers present in bag logs (xsim.log gitignored;
  markers `U3Q_R3_XSIM_PASS` / `U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS`).

## Forbidden claims (not made)

silicon · SoC WNS · BOARD_PASS · Gate14 · U8R · Q-head ·
"LM understands TYPE_CLASS" · HOLD_A retarget · production full-chip close.

## Next lake

P3 learn-store LIMIT. Do not open U8R/U9/PROGRAM from this PASS.
