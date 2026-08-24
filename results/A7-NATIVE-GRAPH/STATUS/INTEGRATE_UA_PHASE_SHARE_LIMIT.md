# integrate_fit — u_a phase-share FALSIFIED

**Agent:** a7-vivado-gate (`86d0f420-6d54-431a-8c9b-e1cc6f511fd5`)  
**Result:** LIMIT (not PASS)  
**Unknown:** `u_a_phase_share` — full 66-tile act bank shared with graph hotset

## FACT (post-route)

| Metric | Value |
|--------|-------|
| BRAM tiles | 135/135 |
| WNS | +1.234 |
| TNS | 0 |
| Model | residual66 + shared66(u_a\|hotset) + A03_proxy3 + banks0 |
| Bit SHA | `AC39D41098BB4D4DC862E58BD5D866CE5F4E34DAE07C04E95E5C8F1CA8D7A704` (NEW measure bit only) |

## Verdict

Full-size `u_a` phase-share does **not** free ≥1 tile vs HS-11 ceiling.  
Gate stays **BLOCKED** behind SEV-0 Top-K + P0 flow; do **not** re-dispatch fit until those close.

## NEXT levers (when unblocked — one at a time)

DDR act spill / shared&lt;66 / shape-sized `u_w` / no concurrent A0.3 — never overwrite frozen LM/01R/02M/A0.3 SHAs.

Artifact: `results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit.md`
