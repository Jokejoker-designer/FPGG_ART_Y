# Close Native AI V1 — DAG (Blueprint V3.1)

Authority: `UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md`.
Close-path design: `docs/native_graph/V31_CLOSURE_PLAN_20260907/PLAN.md` (C00–C13).
Parent dispatch: `docs/native_graph/V31_CLOSURE_PLAN_20260907/PROMPT_GROK_U9R.md`.
Ledger: `docs/native_graph/V31_LEDGER.md`.
Goal (human-only): `NATIVE_V1_MINI_AI_BOARD_PASS`.

```text
P0  U8-R3 bag (XSim structural; MISMATCH)
P1  U5Q-M10-TYPECLASS-SCALE-00 HOST_MODEL PASS
P2  U6T heap 2-phase: XSim PASS; OOC WNS -5.78→-3.35 FAIL (moved to QSE)
P2b U6Q-QSE-LEXICON-TIMING-00 POST_ROUTE_OOC PASS WNS=+0.163 TNS=0 WHS=+0.132
P3  U7C-LEARN-STORE-LIMIT-00 PASS (DEPTH=32 LIMIT, not 800k SCALE)
P4  U7P-PERSISTENCE-IDENTITY-00 PASS (FLUSH==RELOAD XSim)
P5  U7A-ROOT-B-FINAL-00 PASS (close-path store; SoC WDMA OPEN_AUDIT)
P6  U8-R3B-PRODUCTION-GLUE-00 PASS (rtl glue SHA match; U8-R3 XSim PASS; pred=861 MISMATCH)
P7  U8-UNIFIED-SOC-XSIM-00 PASS (raw query→U6→fwd→LM; ENC==CTX; pred=861; SoC top NOT inst)
P7b U8-SOC-ROOTB-WDMA-00 PASS (slice XSim; m_go_ready; not full SoC)
P8  U8R-REMOVE-SYNTHETIC-PRODUCTION PASS (soc_top SYNTHETIC_CAND_GEN=0; fixture default 1)
P9  U9-FINAL-SOURCE-FREEZE-00 PASS (docs/manifest; FINAL_SOURCE_COMMIT=bdddbd68; no bit)
P10 U9R-FINAL-REGRESSION-00 FAIL (R2 QUERY_NO_SNAPSHOT; bag immutable)
C03 C03-QUERY-PENDING-SNAPSHOT-SOURCE-00 PASS (parent snap+pending; cand off)
C02 C02-PRODUCTION-PATH-INTEGRATION-00 PASS (ab_core u_tc; UART soc_top still GAP)
     NEXT = C02 residual UART→tc_tok on soc_top, or C04 — not U9S
P11 U9S / U9I  (NEW unique bit SHA)
P12 U9P-PREPROGRAM-CLOSURE-00
P13 U10 program ONCE + blind exam (HOLD_A 653 unchanged)
P14 56-box then human declare
```

Never program `1F0F2ABB` / `9CA2B30D` / `F24150BD` as the close bit.
gstack: implementer → qa-only auditor → one patch. BIT=NO until U9P.
