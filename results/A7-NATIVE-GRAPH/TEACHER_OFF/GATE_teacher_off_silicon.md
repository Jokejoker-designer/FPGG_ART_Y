GATE: teacher_off_exam
AGENT: a7-hlb-auditor
MODE: HS-02 silicon on SoC bit (stub framing)
CHANGED: results/A7-NATIVE-GRAPH/TEACHER_OFF/{AUDIT_teacher_off_hlb.md,GATE_teacher_off_silicon.md,board_probe.json,uart_blind_exam_transcript.json,LIMIT_lm06_absent.md,sha256_audit.txt,WAITING_BOARD.md} ; harness GATE_teacher_off.md retained CONTROL
WHY: ONE UNKNOWN — SoC D65F3524 + UART stub blind exam vs LIMIT (LM-06 ABSENT) / H_RIVAL proxy+host answers
TESTS: program SoC bit (not proxy); UART E0/S on COM12; live SHA rehash; frozen MATCH
EXPECTED: BOARD-class archive OR honest FAIL/LIMIT; HLB clean; no BOARD_PASS
ACTUAL: Programmed SoC D65F3524…A4DF on Digilent 210319BE776EA; UART RX 91D9/9199; exam_mode=1 mig_calib=1 lm_path=0; proxy NOT programmed; HLB CLEAN (framing); LM-06 ABSENT LIMIT; harness CONTROL retained
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/TEACHER_OFF/AUDIT_teacher_off_hlb.md
SHA256_SOC: D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF
SHA256_AUDIT: 4B0206633B6D0CA90F358ACFD16874A806862FBF031990122F9488B01E225F2D
BOARD_PASS: false
NEXT: section14 / LM weight path for semantic HS-02; do not self-declare BOARD_PASS
