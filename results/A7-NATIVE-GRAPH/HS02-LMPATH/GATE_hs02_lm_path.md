# GATE — hs02_lm_path

GATE: hs02_lm_path
AGENT: a7-hlb-auditor
RESULT: FAIL
CHANGED: results/A7-NATIVE-GRAPH/HS02-LMPATH/{AUDIT_hs02_lm_path_hlb.md,board_probe.json,uart_blind_exam_transcript.json,LIMIT_lm_path_zero.md,frozen_sha_control.txt,sha256_audit.txt,GATE_hs02_lm_path.md}
TESTS: program UA SoC D2C6CF4B (not proxy/weight-only/stub); UART E0/S COM12; lm_path bit5; frozen MATCH; HLB surface
PASS-FAIL: FAIL (lm_path remains 0 through t+210s; exam framing 0x91/exam_mode=1 OK; HLB CLEAN)
ARTIFACT: results/A7-NATIVE-GRAPH/HS02-LMPATH/AUDIT_hs02_lm_path_hlb.md
SHA256: D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C (programmed UA SoC)
AUDIT_SHA256: 27172D0113D532793755D2254B40644F50BFEE44945E80871CB85759C9872825
NEXT: fix board-visible lm_path sticky (smoke/grant_lm) then re-HLB; TinyGPT ABSENT remains LIMIT for full HS-22; no BOARD_PASS
BOARD_PASS: false
allow_loop_done_eng: false
