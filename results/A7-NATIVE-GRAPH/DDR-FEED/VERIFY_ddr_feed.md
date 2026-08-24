# VERIFY_ONLY: ddr_feed (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_DDR_FEED_XSIM_PASS`  
**Evidence class:** XSIM (synthetic LATENCY=24 — not MIG, not BOARD)

## Checks

| Check | Result |
|-------|--------|
| Re-run `tests/xsim/run_a7ng_ddr_feed.tcl` (xvlog+xelab+xsim) | `A7NG_DDR_FEED_XSIM_PASS` / `A7NG_DDR_FEED_XSIM_OK` exit 0 |
| STALL_REDUCED | **1** — baseline 0.961544 → best 0.475410 (−50.6% rel) |
| DROP=0 | **PASS** — `ANY_DROP=0`; all 32 sweep cells `drop=0` |
| Best cell (TB) | burst=4 out=8 stall_frac=0.475410 |
| Recs/cycle | 0.038456 → 0.524590 |
| Live RTL/bits vs archive SHA | ALL MATCH (`frozen_sha_verify.txt`) |
| WM-00 control | `1F7F3950…` MATCH |
| mem_schema_v1 | `F0FE426E…` MATCH |
| LM-06 / 01R / 02M / A0.3 | MATCH |

## Sweep confirmation (re-sim bit-exact vs implementer)

| Metric | Value |
|--------|------:|
| Cells | 32 (burst{1,4,8,16} × out{1,2,4,8} × seed{0,1}) |
| drop≠0 rows | **0** |
| Baseline stall_frac (1,1) | 0.961544 |
| Best stall_frac | 0.475410 |
| STALL_REDUCED | 1 |

## Logs / controls

- `results/A7-NATIVE-GRAPH/DDR-FEED/xsim_ddr_feed_verify.log`
- `results/A7-NATIVE-GRAPH/DDR-FEED/frozen_sha_verify.txt`
- Implementer: `results/A7-NATIVE-GRAPH/DDR-FEED/GATE_ddr_feed.md`
- Marker: `results/A7-NATIVE-GRAPH/DDR-FEED/A7NG_DDR_FEED_XSIM_PASS.md`

## Explicit non-claims

H_RIVAL OPEN (not MIG). No 100 MHz / ARCH_PASS. No BOARD_PASS. No RTL/golden edit. No LOOP_STATE flip (parent/orchestrator).
