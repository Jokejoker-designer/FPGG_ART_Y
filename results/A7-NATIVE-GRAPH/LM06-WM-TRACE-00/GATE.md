# GATE lm06_wm_trace_00 (Phase D — parallel, independent of graph late-mat)

**ONE UNKNOWN:** What is `u_a` M_peak lifetime and tile residency under frozen LM-06 law?  
**Evidence class:** TRACE / POST_ROUTE_PROXY (not BOARD, not existence pred=664)  
**Authority:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md` §2.2  
**Forbidden:** blind cut to 32 BRAM; overwrite frozen `arty_a7_lm06` bit; treating this as HS-22.

## Why independent of UART pred=664

This measures **working-set physics of already-frozen LM-06**, not Native V1 existence.  
Existence still requires UART `pred=664` on the E2R bit; this gate must not program COM12.

## Deliverable for this wave (session B)

1. Freeze a measurement plan: unit of analysis = one LM-06 tile phase, not 100k cycles as fake N.
2. Name signals / reports already in repo (`LM06_BRAM_OWNERSHIP`, `a7ng_lm06_wm_*.sv`, post-route DCP if present).
3. Do **not** open `lm06_wm_ladder` (BLOCKED until this trace exists).

Owner: `a7-ng-memory-arch`. Skill: `a7-native-graph-gate`, `scientific-method-native-ai`.

**PLAN (this wave):** `PLAN.md` — UNIT = one commanded phase × sequence, not 100k cycles.  
**Inventory parser:** `tools/lm06_wm_trace_parse.py` → `INVENTORY.json` (existing files only; `M_peak` stays MISSING until `WMTR_REC`).  
**Ladder:** still **do not open**.
