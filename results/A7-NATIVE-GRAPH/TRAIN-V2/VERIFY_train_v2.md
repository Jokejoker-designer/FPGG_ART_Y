# VERIFY_ONLY: train_v2 (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_TRAIN_V2_HARNESS_PASS`  
**Evidence class:** HARNESS (pytest) — **not** XSim silicon, **not** BOARD_PASS, **not** HS-02  
**XSim:** ABSENT (no `tests/xsim/native_graph` TB for this gate; harness is the evidence class)

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | Implementer archived HARNESS PASS; marker + GATE claim frozen MATCH + V2>warm |
| UNKNOWN | Independent re-run: pytest still PASS? frozen bits MATCH? class stayed HARNESS? |
| H_CANDIDATE | pytest 18/18 + frozen MATCH + summary SHA stable; remain HARNESS |
| H_RIVAL | Inflate to XSim/silicon / BOARD_PASS; or frozen overwrite; or nondeterministic rewrite |
| FALSIFIER | Any frozen MATCH=False; claim silicon; edit goldens/RTL; board_pass=true |
| UNIT | fact bag / query set (pytest gates) — not clock cycles |
| CONTROL | LM-06 / 01R / 02M / A0.3 bits; control dump SHA `9E746E3F…` |
| METRICS | pytest exit; gates_all; EXPERIMENT_SUMMARY SHA; frozen MATCH; evidence_class=HARNESS |

## Checks

| Check | Result |
|-------|--------|
| `pytest tests/native_graph/test_train_v2.py tests/native_graph/test_ng00_anti_leak.py -v` | **18 passed** |
| Marker file `A7NG_TRAIN_V2_HARNESS_PASS.md` | Present; `Evidence_class=HARNESS`; `board_pass=false` |
| `EXPERIMENT_SUMMARY.json` SHA256 | **MATCH** `32A91009099A33350E8D8A7AD14A5BD21C8DCCB8FE8B026A6060C58FC836A8AE` |
| Control dump content SHA | **MATCH** `9E746E3F6DD5F488F4266C274019D85F2E9C8AF764492066060B36BA2AD97F64` (unchanged) |
| All preregistered gates | **true** (15/15) |
| metrics_20 top1 Run A / warm / control | **1.00 / 0.50 / 0.75** (V2>warm, V2≥control) |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| Upgrade HARNESS → XSim / silicon / BOARD | **REFUSED** |
| RTL / golden / frozen bits edited this verify | **No** |

## Logs / controls

- `results/A7-NATIVE-GRAPH/TRAIN-V2/pytest_train_v2_verify.log`
- `results/A7-NATIVE-GRAPH/TRAIN-V2/frozen_sha_verify.txt` (this verify rehash)
- Implementer GATE: `results/A7-NATIVE-GRAPH/TRAIN-V2/GATE_train_v2.md`
- Prior control: `results/A7-NATIVE-GRAPH/TRAIN-V2/frozen_sha_control.txt`

## Explicit non-claims

- No XSim functional proof for train_v2  
- No silicon / HS-02 / board program  
- No Native V1 BOARD_PASS  
- No LOOP_STATE flip (parent/orchestrator / auditor)  
- integrate_fit PASS_NARROW ≠ §14 SoC (unchanged)  
