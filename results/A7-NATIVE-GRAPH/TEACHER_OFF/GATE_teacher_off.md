GATE: teacher_off_exam
ROLE: HARNESS CONTROL ONLY (do not delete; not HS-02 silicon)
CHANGED: tests/native_graph/test_teacher_off_exam.py
WHY: §14 teacher-off flags + held-out/unrelated/contradiction packets (shape gate)
TESTS: pytest tests/native_graph/test_teacher_off_exam.py -q
EXPECTED: A7NG_TEACHER_OFF_HARNESS_PASS
ACTUAL: pytest PASS (reconfirmed 2026-08-22)
PASS/FAIL: PASS (harness CONTROL only)
ARTIFACT: results/A7-NATIVE-GRAPH/TEACHER_OFF/GATE_teacher_off.md
SILICON: see GATE_teacher_off_silicon.md + AUDIT_teacher_off_hlb.md → PASS_NARROW (UART stub framing; LM-06 ABSENT LIMIT)
SHA256: n/a (control)
NEXT: semantic HS-02 / LM path still OPEN; harness stays CONTROL only
