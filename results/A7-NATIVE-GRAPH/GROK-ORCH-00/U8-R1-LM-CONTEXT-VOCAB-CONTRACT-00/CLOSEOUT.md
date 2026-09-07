# CLOSEOUT — U8-R1-LM-CONTEXT-VOCAB-CONTRACT-00

```text
GATE                     = U8-R1-LM-CONTEXT-VOCAB-CONTRACT-00
HEAD                     = 1bf9966b649361539ee16fb2b426514a83559a56
RTL_EDIT                 = NO
RESULT                   = MEASURE_PASS
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
EVIDENCE_CLASS           = RTL_FACT + HOST_MODEL

PROTOCOL                 = lm-ctx-typeclass-serial-v1
PROTOCOL_SHA256          = f88f6db7a73e25a6dfdb849bd781fac7a190a11b3964f234860de43829c4ed97
MAPPING_TABLE            = EMPTY
SEMANTIC_LM_CLAIM        = NO

QHEAD                    = NO
BIT                      = NO
PROGRAM                  = NO
HOLD_A_ORACLE_RETARGET   = NO
```

R1 did its job: inspect and freeze the **contract**, not fake token IDs.

## NEXT (do not auto-start R2)

Owner chooses:

**1.** Train/version a checkpoint that can read TYPE_CLASS serialization,
then freeze a real mapping table SHA, then U8-R2.

**2.** Explicitly authorize U8-R2 as **structural-only** encoder XSim
under `LM_CHECKPOINT_CONTEXT_MISMATCH` (no semantic LM / no OUT=653).

Do not jump to production glue (U8-R3) from here.
