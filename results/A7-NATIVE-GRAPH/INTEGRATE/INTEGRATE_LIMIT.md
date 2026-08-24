# GATE: integrate_fit — PASS_NARROW (ownership-audited cut) — 2026-08-22

```text
GATE: integrate_fit
UNKNOWN: ownership_audited_tile_cut (prior u_a_phase_share remains FALSIFIED)
TESTS: measure_integrate_fit_own_cut.tcl (RAMB36E1 proxy top)
EXPECTED: BRAM<=130 WNS>=0 TNS=0 frozen MATCH
ACTUAL: BRAM=130 WNS=1.365 TNS=0 (post-route)
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit.md
SHA256: D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3
```

## Narrow scope (honest)

1. Numeric Prefer≤130 + WNS/TNS met on ownership-audited proxy.
2. Concurrent A0.3 dropped; MIG BRAM=0 cited from NG-03 (not re-built here).
3. DDR corruption / functional act-spill RTL / WM-00 timing **not** closed.
4. Frozen LM-06 / 01R / 02M / A0.3 SHAs **MATCH** (HS-20).
5. AI does **not** declare BOARD_PASS.

## Still dead levers

- Full-66 `u_a` phase-share + A0.3 → 135 LIMIT  
- Naive glue 243/135 HS-11 FAIL  
- WM-00 WNS=−290.499 sold as bankable — forbidden  
