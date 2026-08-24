# VERIFY_ONLY: teacher_off_exam (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — harness CONTROL intact; UART stub framing only  
**Not claimed:** semantic HS-02 retrieval, Native V1 BOARD_PASS, LM-06 weight fabric, XSim functional pass  
**XSim marker:** **ABSENT** (`tests/xsim/native_graph` missing; no `A7NG_*_XSIM_PASS` for this gate)  
**Harness marker:** `A7NG_TEACHER_OFF_HARNESS_PASS` (pytest shape gate only)

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | HLB PASS_NARROW BOARD_UART_STUB; harness GATE retained; SoC D65F3524… programmed; lm_path=0; LM-06 ABSENT LIMIT |
| UNKNOWN | Independent verify: harness CONTROL still green? inflate stub framing → semantic HS-02? XSim invented? |
| H_CANDIDATE | pytest CONTROL PASS; no XSim; PASS_NARROW stands; semantic HS-02 remains OPEN/LIMIT |
| H_RIVAL | Upgrade to full HS-02 / BOARD_PASS; delete harness CONTROL; invent XSim marker; host-grade answers |
| FALSIFIER | pytest FAIL; harness file deleted/rewritten to claim silicon; retrieval_answers non-null from host |
| UNIT | pytest cases + file SHA / UART transcript fields (not query-cycle accuracy) |
| CONTROL | `tests/native_graph/test_teacher_off_exam.py`; proxy bit D2FC41A7… not HS-02 vehicle; frozen LM/01R/02M/A0.3 |
| METRICS | pytest exit 0; marker print; SoC≠proxy; lm_path=0; hs02_semantic_retrieval=LIMIT_NOT_CLAIMED |

## Checks

| Check | Result |
|-------|--------|
| `pytest tests/native_graph/test_teacher_off_exam.py -q` | **3 passed** (2026-08-21T22:42Z reconfirm) |
| Marker `A7NG_TEACHER_OFF_HARNESS_PASS` | present in test; CONTROL role in `GATE_teacher_off.md` |
| Telemetry shape: teacher=0 learn=0 freeze=1 external_LLM=0 | **PASS** (harness assertions) |
| Blind exam JSON held_out / unrelated / contradiction shape | **PASS** (NG-08 bag; shape only) |
| XSim TB under `tests/xsim/native_graph` | **ABSENT** |
| SoC bit live SHA | **MATCH** `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` |
| Proxy CONTROL live SHA | **MATCH** `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` (**≠ SoC**) |
| Frozen LM-06 / 01R / 02M / A0.3 | **MATCH** (per `sha256_audit.txt` + live rehash) |
| UART transcript `evidence_class` | `BOARD_UART_STUB` |
| UART `hs02_semantic_retrieval` | `LIMIT_NOT_CLAIMED` |
| `lm_path` / `lm06_weight_fabric` | `0` / `ABSENT` |
| `retrieval_answers` / `host_graded_answers` | `null` / `false` |
| Inflate PASS_NARROW → semantic HS-02 | **REFUSED** |
| RTL / golden / frozen bits edited this verify | **No** |

## Artifacts consulted (read-only)

- `results/A7-NATIVE-GRAPH/TEACHER_OFF/GATE_teacher_off.md` — HARNESS CONTROL ONLY
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/GATE_teacher_off_silicon.md` — PASS_NARROW stub framing
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/AUDIT_teacher_off_hlb.md`
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/board_probe.json`
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/uart_blind_exam_transcript.json`
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/LIMIT_lm06_absent.md`
- `results/A7-NATIVE-GRAPH/TEACHER_OFF/sha256_audit.txt`
- `tests/native_graph/test_teacher_off_exam.py`

## Explicit non-claims

- No XSim functional proof for teacher_off_exam  
- No semantic held-out / unrelated / contradiction **silicon** retrieval accuracy  
- No LM-06 weight fabric / HS-22 answer path  
- No Native V1 BOARD_PASS  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)  
- Harness remains CONTROL — do not delete; do not sell as HS-02 silicon  
