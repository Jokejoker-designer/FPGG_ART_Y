# CLOSEOUT — C02-PRODUCTION-PATH-INTEGRATION-00

```text
GATE                     = C02-PRODUCTION-PATH-INTEGRATION-00
RESULT                   = PASS
SCOPE                    = ab_core u_tc shares TinyGPT; chain refactor
FULL_SOC_RESULT          = INTEGRATION_GAP
UART_TO_TC               = NOT WIRED on soc_top
SOC_TOP_INSTANTIATED     = NO
MARKER                   = U8_UNIFIED_SOC_XSIM_PASS (prod_tc_lm inside chain)
PRED_OBS                 = 861
SEMANTIC_LM_CLAIM        = NO
BIT                      = NO
PROGRAM                  = NO
U9S                      = NO
READY_FOR_FINAL_SYNTH    = NO
```

## Allowed

`a7ng_prod_tc_lm` is the LM-less production TYPE_CLASS path (QSE→U6→enc→fwd).
`a7ng_typeclass_soc_chain` wraps it + one TinyGPT. `ab_core` instantiates `u_tc`
and muxes ctx/start_fwd when `tc_sel` (SYNTH=0 and path live). Bind remains
fallback. P7 raw-query XSim still PASS after refactor.

## Not claimed

UART decoder on `soc_top` feeding `tc_tok_*`. MIG/full top XSim. C04 WDMA dest.
BOARD_PASS. OUT=653.

## NEXT

Wire UART raw bytes → `tc_tok_*` on soc_top (still C02 residual) or C04.
Not U9S.
