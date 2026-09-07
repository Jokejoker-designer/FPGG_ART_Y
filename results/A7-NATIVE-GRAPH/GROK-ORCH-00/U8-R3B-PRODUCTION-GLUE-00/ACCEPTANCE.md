# ACCEPTANCE — U8-R3B (qa-only)

```text
VERDICT   = PASS
OVERCLAIM = false
FRAUD     = false
SCOPE     = rtl promote of bag glue + U8-R3 XSim
```

SHA of `rtl/native_graph/lm/a7ng_lm_ctx_fwd_v1.sv` matches the U8-R3 bag
file. Marker `U8_R3_TYPECLASS_TOPK_TO_LM_PASS`. ENC==CTX stream.
pred_obs=861 is **not** HOLD_A 653 and is **not** a semantic LM claim.
Host tok/w/win/addr = 0. BIT=NO PROGRAM=NO.

Do not treat this as U8R, SoC, or READY_TO_PROGRAM. Dirty MIG blocks P7.
