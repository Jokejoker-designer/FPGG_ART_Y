# VERIFY dispatch — ready when Grok releases lock after E0 PASS

**Do not run while `lock.owner=grok` and gate still FAIL.**  
**Date:** 2026-08-24T20:51:00+07:00  
**R1 prep:** CLOSED — ledger + DCP gate + Class A lock in `R6-PARALLEL-BOARD-PREP-00/`  
**Trigger:** CLOSEOUT shows `NATIVE_EXISTENCE_XSIM_PASS` + `pred=664` marker in `xsim_ab_mig.log`

When CLOSEOUT shows `NATIVE_EXISTENCE_XSIM_PASS` and `lock.owner` is `none` or Cursor:

```text
1. Task a7-ng-xsim-verify   VERIFY_ONLY  gate=native_v1_ab_integrate_accept_00
2. Task a7-hlb-auditor      VERIFY_ONLY  same gate
3. Task a7-evidence-auditor VERIFY_ONLY  same gate
   — refuse PASS if DISPATCH_LOG last gate mismatch
   — grade against STATUS/E0_ACCEPTANCE_CRITERIA.md
4. If post-route artifacts present: Task a7-vivado-gate VERIFY_ONLY
5. On auditor PASS: open E1 per STATUS/E1_COFIT_CHECKLIST.md
```

Parent remains orchestrator-only (no RTL).
