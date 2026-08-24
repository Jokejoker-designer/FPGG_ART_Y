# E1 — Actual co-fit synth/P&R checklist

**Opens only after:** `NATIVE_EXISTENCE_XSIM_PASS` for AB integrate  
**Date:** 2026-08-24T15:35:00+07:00  
**Doctrine:** Do not chase arbitrary ≤130 BRAM until **this** hierarchy fails device limits.

---

## ONE UNKNOWN

Does the **actual** A+B integrated hierarchy (live SOA/MIG + bind + TinyGPT + snap contract) fit `xc7a100tcsg324-1` with legal timing?

## Hard device limits

| Resource | Limit |
|----------|-------|
| BRAM (RAMB36 equiv) | ≤ 135 |
| LUT / FF / DSP | ≤ device |
| WNS | ≥ 0 |
| TNS | = 0 |

## Required reports (file-backed)

- Hierarchy utilization (BRAM/LUT/FF/LUTRAM/DSP by module)  
- Timing summary + critical paths  
- Clock interaction note  
- Bit SHA **only if** bitstream generated; existence board still needs human COM12 auth later  

## Decision tree

```text
IF FIT + WNS/TNS OK:
  → STOP BRAM optimization on critical path
  → proceed to E2 runbook (HUMAN_AUTH_REQUIRED)

IF overflow:
  → identify EXACT physical owner (not additive guess)
  → open ONE memory experiment (E1-M): LUTRAM / phase overlay / snap / DDR-back / recompute
  → re-run E1 after that single change
```

## Forbidden

- Proxy memory arithmetic as final FIT proof  
- Blind parameter compression  
- Opening HNSW / extra PEs / NTDE to “make fit”  
- Parent editing RTL — use Task `a7-vivado-gate` VERIFY + implementer only if FIT fail needs one memory patch  

## Inputs from Project A (already DONE_ENG)

`LM06-SNAPSHOT-LUTRAM-01`: full post-route **130 BRAM**, WNS+0.125 — available lever if E1 needs −2 BRAM class; not auto-applied.
