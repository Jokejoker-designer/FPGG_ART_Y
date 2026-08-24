# GATE: integrate_fit FULL SoC — PASS_NARROW — 2026-08-22

```text
GATE: integrate_fit
UNKNOWN: full_soc_mig_lm_arb_graph_pe_uart
TESTS: measure_integrate_fit_soc.tcl
EXPECTED: BRAM<=135 prefer<=130; WNS>=0; TNS=0; PE measured; != proxy SHA
ACTUAL: BRAM=0 WNS=0.952 TNS=0 PE=16 (hier) SHA=D65F3524…
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit_soc.md
SHA256: D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF
```

## Narrow / LIMIT (honest)

1. Numeric device BRAM + WNS/TNS met on **real** MIG+PE+arb+UART SoC (not RAMB36 proxy).
2. PE=16 measured post-route fabric (`u_sc` 1046 LUT) — falsifier “PE optimized away sold as 16” **did not fire**.
3. **LIMIT:** full LM-06 weight fabric (132 BRAM) **ABSENT** — LM arbitration + evidence compose only; HS-22 §14 LM path remains OPEN.
4. UART exam stub present (status 0x91 teacher=0/learn=0/freeze=1 framing); **blind exam DEFERRED** to `teacher_off_exam`.
5. Proxy own_cut `D2FC41A7…` retained as CONTROL; frozen LM/01R/02M/A0.3 MATCH.
6. AI does **not** declare BOARD_PASS.
