# CONTROL — synthetic DDR-FEED (retained)

Source: `results/A7-NATIVE-GRAPH/DDR-FEED/` (AUDIT: H_RIVAL OPEN_NOT_MIG at ddr_feed gate).

| Cell | stall_frac | recs/cyc | Notes |
|------|-----------:|---------:|-------|
| burst=1,out=1 | 0.961544 | 0.038456 | baseline |
| burst=4,out=8 | 0.475410 | 0.524590 | best |

LATENCY=24 synthetic only. DROP=0. Evidence_class=XSIM. Not Digilent MIG.

Post-repair comparison: Digilent MIG_XSIM rows in `MIG_SWEEP_ROW.md` (0.958710 → 0.549296). Do not equate synthetic best with MIG.
