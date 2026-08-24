# GATE: train_v2 (A7-NATIVE-GRAPH-TRAIN-V2)

**Agent:** `a7-ng-teacher-protocol`  
**Evidence class:** HARNESS (not BOARD; not HS-02 silicon)  
**Marker:** `A7NG_TRAIN_V2_HARNESS_PASS`  
**Date:** 2026-08-22  
**Board:** Digilent Arty A7-100T only  

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | representation/WM/TermGen law changed; old learned-state attribution broken if continued |
| UNKNOWN | after reset learned memory only (keep RTL/bitstream arch; freeze old model as control), does Run A/B on same 20/40 facts show TRAIN-V2 improves vs frozen control under teacher=ON learning=ON? |
| H_CANDIDATE | TRAIN-V2 from zero under versioned law `a7ng-train-v2` beats warm-contaminant and ≥ control on preregistered metrics |
| H_RIVAL | harness-only / host-graded illusion; OR control contaminated by edit |
| FALSIFIER | old model edited/deleted; encoder/LM-06 overwritten; metrics not preregistered; BOARD_PASS self-declared |
| UNIT | fact bag / query set — not cycle count alone |
| CONTROL | frozen old-model dump SHA + LM-06/01R/02M/A0.3 SHAs MATCH |
| METRICS | declared in `METRICS_PREREGISTERED.json` before run |

## Verdict

**PASS (protocol / HARNESS).** H_CANDIDATE supported on preregistered 20/40 bags:

| Arm | top1 | topk@3 | hn_fp | paraphrase |
|-----|------|--------|-------|------------|
| CONTROL (old law) | 0.75 | 0.875 | 0 | 1.0 |
| WARM (old priors + new law, no reset) | 0.50 | 0.875 | 0 | 0.5 |
| TRAIN-V2 Run A | **1.00** | **1.00** | 0 | 0.5 |
| TRAIN-V2 Run B (after RESET) | 0.75 | 1.00 | 0 | 0.25† |

† Held-out gold still mapping-A; B forgets A on remapped train queries (`forgets_a=true`).

Frozen bits MATCH. Control dump SHA unchanged. No BOARD_PASS. `integrate_fit` PASS_NARROW ≠ §14 SoC.

## CHANGED

| Path | Role |
|------|------|
| `python/native_graph/train_v2_harness.py` | NEW — attribution experiment |
| `tests/native_graph/test_train_v2.py` | NEW — V2-C1/C2/S20/S40/AB/BLIND |
| `results/A7-NATIVE-GRAPH/TRAIN-V2/**` | Archive only |
| `docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md` | Status → harness archived |
| `docs/native_graph/TEST_MATRIX.md` | TRAIN-V2 rows unblocked |
| `docs/native_graph/CONTRACT_FREEZE.md` | law_id note |

**NOT changed:** LM-06/01R/02M/A0.3 bits; encoder RTL; NG DONE_ENG archives; integrate_fit bit.

## TESTS

| ID | Result |
|----|--------|
| V2-C1 control present / SHA intact | PASS |
| V2-C2 reset clears learned; bits MATCH | PASS |
| V2-S20 teacher-off bag | PASS |
| V2-S40 after S20 (same first 20 facts) | PASS |
| V2-AB Run A → RESET → Run B forgets A | PASS |
| V2-BLIND no attention leak | PASS |
| pytest `test_train_v2.py` + `test_ng00_anti_leak.py` | 18 passed |
| Frozen LM/01R/02M/A0.3 | MATCH |

## SHA256 (primary)

`32A91009099A33350E8D8A7AD14A5BD21C8DCCB8FE8B026A6060C58FC836A8AE  EXPERIMENT_SUMMARY.json`  
Control dump: `9E746E3F6DD5F488F4266C274019D85F2E9C8AF764492066060B36BA2AD97F64`  
(full tree: `SHA256.txt`)

## NEXT

Parent `--dispatch` / auditor. Scale ladder beyond 40 remains OPEN. No BOARD_PASS.
