# SCI_METHOD session lock — 2026-08-22

**Loaded:** scientific-method-native-ai + hypothesis-generation + experimental-design + scientific-critical-thinking + 04/15 + LOOP_STATE + PLAN_KDENSE_20260822.

**Immediate unknown (Phase A1):** Is NG-06R-WIDE evidence sufficient to flip `ng06_wide_dispatch` OPEN → DONE_ENG?

```text
OBSERVATION: LOOP OPEN vs GATE util16=100% (CONFLICTING)
UNKNOWN: one — evidence sufficiency under multi ready-pattern rule
H_CANDIDATE: N_WAY=16 allocator feeds 16 PE under declared util gate (H-disp)
H_RIVAL: 100% util is single always-ready hotset artifact (pseudoreplication of cycles)
FALSIFIER: util collapses or starve>0 under ready-sparsity bags; or TB asserts only pop_valid_o
UNIT: independent ready-pattern / seed bag — NOT 100k cycles as 100k queries
CONTROL: SHA of a7ng_multi_agent_share.sv vs SHA256.txt; prior 1-way baseline
METRICS: util, max_jpc ladder, starve — preregistered in feedback/PLAN
Evidence class for this audit: XSIM (not BOARD)
```

Parent: STATUS only. Auditor first. No RTL in parent.
