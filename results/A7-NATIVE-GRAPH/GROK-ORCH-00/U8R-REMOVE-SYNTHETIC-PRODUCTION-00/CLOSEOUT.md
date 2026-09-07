# CLOSEOUT — U8R-REMOVE-SYNTHETIC-PRODUCTION-00

```text
GATE                     = U8R-REMOVE-SYNTHETIC-PRODUCTION-00
RESULT                   = PASS
EVIDENCE_CLASS           = XSIM + RTL_FACT
FIRST_DIVERGENCE         = none
WIRE                     = g1g5 SYNTHETIC_CAND_GEN
PROD_PARAM               = arty_a7_ng_native_v1_ab_soc_top u_ab SYNTHETIC_CAND_GEN=0
FIXTURE_DEFAULT          = 1 (gate14 xsim / HOLD_A cand_* walk)
MARKER                   = U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS
REGRESSION_P7B           = U8_SOC_ROOTB_WDMA_PASS
REGRESSION_TYPECLASS     = U8_UNIFIED_SOC_XSIM_PASS pred=861 MISMATCH
BIT                      = NO
PROGRAM                  = NO
QHEAD                    = NO
GATE14_PASS              = NO
BOARD_PASS               = NO
```

## What closed

Production SoC C9 ID source is parent `graph_id_i` (SOA / TYPE_CLASS heap),
not `cand_nid(query_id)`. Query-valid into the synthetic cand walk is
forced 0 when `SYNTHETIC_CAND_GEN=0`. Fixture instances keep default 1.

XSim: prod persist IDs = 65,66,67 from parent; fixture idle IDs = 0.

## Not claimed

- `native_ctx_bind` still in `a7ng_native_v1_ab_core` (NID-era LM pack).
- TYPE_CLASS chain is not yet the UART exam path inside soc_top.
- SOA wavefront retrieval still exists (existence path).
- HOLD_A 653 unchanged; pred_obs on TYPE_CLASS chain still 861 MISMATCH.
- Not a PROGRAM license.

## NEXT

U9 freeze docs only after this bag is accepted. Not U9S/bit.
