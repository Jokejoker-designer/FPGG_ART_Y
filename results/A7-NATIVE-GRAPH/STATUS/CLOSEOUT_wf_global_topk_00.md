# CLOSEOUT — wf_global_topk_00 (orchestrator status sync)

**Date:** 2026-08-22  
**Result:** **DONE_ENG** / **PASS_NARROW** / `XSIM`  
**Auditor:** [Evidence auditor](912d765f-5fc4-48ad-aca7-3ab22ad272b3) — `allow_loop_done_eng: true`  
**HLB:** [HLB auditor](8a5c6e4c-b43b-4abc-8135-c0b5ef3ae193) — PASS_NARROW  

## LIMIT (auditor MAJOR)

- Integrated `a7ng_ddr_wavefront_top` path **not** in XSim project — unit accumulator only  
- `lane_pop` forward-reference in wavefront top — fix in `wf_global_topk_integrated_00`  
- `carried_risk_r1`: **PARTIAL** until integrated gate  

## Verify still pending (machine pause)

| Agent | Status |
|-------|--------|
| `a7-ng-xsim-verify` | **ERROR** (connection failed — re-run) |
| `a7-vivado-gate` | **ERROR** (connection failed — re-run) |
| `a7-evidence-auditor` | PASS_NARROW |
| `a7-hlb-auditor` | PASS_NARROW |

## Next on resume

1. Finish xsim/vivado verify (optional re-run)  
2. Dispatch **`wf_global_topk_integrated_00`** (QUEUED)  
3. Then **`descriptor_contract_00`** per Masterplan §2.1  

`LOOP_STATE.next` remains **STOP** until machine pause lifts.
