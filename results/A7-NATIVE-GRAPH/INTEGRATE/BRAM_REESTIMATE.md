# BRAM re-estimate — integrate_fit ownership cut (2026-08-22)

## Prior (dead)

| Lever | BRAM | Verdict |
|-------|-----:|---------|
| Naive glue | 243/135 | HS-11 FAIL |
| Banks replace 01R/02M keep LM+A0.3 | 135/135 | LIMIT |
| `u_a_phase_share` full-66 + A0.3 | 135/135 | **FALSIFIED** for ≤134 |

## Ownership-audited cut (this run)

Post-route `measure_integrate_fit_own_cut.tcl` forced `RAMB36E1`:

| Block | Tiles | Notes |
|-------|------:|-------|
| residual LM (`u_w`+`u_snap`) | 66 | always present |
| shared cut (`u_a` DDR-spill ⊕ hotset) | 64 | exclusive owner FSM |
| A0.3 concurrent | 0 | dropped (narrow) |
| banks + scorer | 0 | prior measure |
| MIG | 0 | cited NG-03 |
| **Total** | **130** | Prefer ≤130 **PASS** |

| Timing | Value | Gate |
|--------|------:|------|
| WNS | 1.365 ns | PASS |
| TNS | 0.000 | PASS |
| WHS | 0.067 ns | OK |
| THS | 0.000 | OK |

**Verdict:** `ownership_audited_tile_cut` → **PASS_NARROW** (numeric).  
WM-00 OOC WNS=−290.499 remains **OPEN / not bankable**. No BOARD_PASS.
