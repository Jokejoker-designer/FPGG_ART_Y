# VERIFY_ONLY: frontier_shootout (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_FRONTIER_SHOOTOUT_XSIM_PASS`  
**Evidence class:** XSIM (not silicon, not BOARD_PASS)

## Checks

| Check | Result |
|-------|--------|
| Re-run xvlog/xelab/xsim `tb_a7ng_frontier_shootout` | `A7NG_FRONTIER_SHOOTOUT_XSIM_PASS queries=64` exit 0 |
| Top-8 law SHA (`a7ng_topk.sv` / `a7ng-topk-global-v1`) | **MATCH** `F671FCB1…AA197636` |
| Bucket control SHA (NG-02R-FLOW) | **MATCH** `CE38FEC3…ACDD2C565` |
| Systolic / twolevel / TB SHA vs archive | **MATCH** |
| Frozen LM-06 / 01R / 02M / A0.3 | **MATCH** |
| RTL/golden edited | **No** |

## Logs / controls

- `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/xsim_shootout_verify.log`
- `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/xvlog_shootout_verify.log`
- `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/xelab_shootout_verify.log`
- `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/frozen_sha_verify.txt`
- Implementer: `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/closeout.md`

## Explicit non-claims

No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator). No RTL/golden change. Shootout ranking not re-judged here — XSim + SHA controls only.
