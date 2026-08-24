# VERIFY_ONLY: termgen (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_TERMGEN_XSIM_PASS`  
**Law:** `a7ng-termgen-v0`  
**Evidence class:** XSIM (not silicon, not BOARD_PASS)

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | Implementer claimed TermGen XSim PASS + control SHAs |
| UNKNOWN | Does independent re-sim reproduce marker with controls intact? |
| H_CANDIDATE | Re-run xvlog/xelab/xsim yields `A7NG_TERMGEN_XSIM_PASS`; Top-8/bucket/frozen MATCH |
| H_RIVAL | Stale log / golden edit / control SHA drift |
| FALSIFIER | Missing marker; any control MATCH=False; golden SHA change |
| UNIT | 32 candidate vectors, law bag (not cycles-as-queries) |
| CONTROL | Top-8 global v1; frontier bucket; scorer lane/array; LM-06/01R/02M/A0.3 |
| METRICS | Marker present; SHA MATCH; golden SHA unchanged |

## Checks

| Check | Result |
|-------|--------|
| Re-run xvlog/xelab/xsim `tb_a7ng_termgen` (no oracle regen) | `A7NG_TERMGEN_XSIM_PASS` law=`a7ng-termgen-v0` lanes=16 vectors=32 families=hamming,bind,intent_context,path |
| Primary lane SHA | **MATCH** `DD637EDA…22DF5218` |
| Top-8 law SHA (`a7ng_topk.sv`) | **MATCH** `F671FCB1…AA197636` |
| Bucket control SHA | **MATCH** `CE38FEC3…ACDD2C565` |
| Scorer lane/array (untouched) | **MATCH** |
| Golden bag SHA | **MATCH** `7BBE92AE…CF8BE0` (unchanged after verify) |
| Frozen LM-06 / 01R / 02M / A0.3 | **MATCH** |
| RTL/golden edited this verify | **No** |

## Logs / controls

- `results/A7-NATIVE-GRAPH/TERMGEN/xsim_termgen_verify.log`
- `results/A7-NATIVE-GRAPH/TERMGEN/xvlog_termgen_verify.log`
- `results/A7-NATIVE-GRAPH/TERMGEN/xelab_termgen_verify.log`
- `results/A7-NATIVE-GRAPH/TERMGEN/frozen_sha_verify.txt`
- Implementer: `results/A7-NATIVE-GRAPH/TERMGEN/GATE_termgen.md`

## Explicit non-claims

No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator). No RTL/golden change. No candidates/s throughput claim. OOC DSP/WNS not re-judged here (vivado-gate).
