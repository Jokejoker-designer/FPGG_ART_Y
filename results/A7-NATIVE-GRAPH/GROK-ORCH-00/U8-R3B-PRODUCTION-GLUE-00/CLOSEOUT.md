# CLOSEOUT — U8-R3B-PRODUCTION-GLUE-00

```text
GATE                     = U8-R3B-PRODUCTION-GLUE-00
RESULT                   = PASS
EVIDENCE_CLASS           = RTL_FACT + XSIM
RTL_EDIT                 = YES (promote only; no logic change)
DST                      = rtl/native_graph/lm/a7ng_lm_ctx_fwd_v1.sv
SHA256                   = 63E32A9BE0A9AA5BCC0679F6D2A78218CA5B11900872636A1DC2716AC52ABF4C
BAG_SHA_MATCH            = YES
ENCODER_EDIT             = NO
BIND                     = not a7ng_native_ctx_bind
U8_R3_MARKER             = U8_R3_TYPECLASS_TOPK_TO_LM_PASS
ENC_CTX_STREAM           = 1 1 0 0 1 1 0 1 1 1 1 0
CTX_WE_BEATS             = 2
START_FWD_PULSES         = 1
GLUE_PRED                = 861
CORE_PRED                = 861
HOST_SEMANTIC            = 0
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
BIT                      = NO
PROGRAM                  = NO
QHEAD                    = NO
HOLD_A_ORACLE_RETARGET   = NO
```

Byte-identical promote of U8-R3 bag glue into `rtl/`. U8-R3 `run_xsim.tcl`
now xvlogs the rtl copy. Re-run PASS after QSE 30+30 + HEAPIFY load/compare.

## Forbidden claims (not made)

LM understands TYPE_CLASS · silicon glue · OUT=653 · Gate14 · BOARD_PASS ·
U8R complete · SoC MIG XSim.

## NEXT

`U8-UNIFIED-SOC-XSIM-00` is **BLOCKED** while `vivado/ip/mig_7series_0`
is dirty. Do not start U8R/U9/PROGRAM. Do not reseat `1F0F2ABB`.
