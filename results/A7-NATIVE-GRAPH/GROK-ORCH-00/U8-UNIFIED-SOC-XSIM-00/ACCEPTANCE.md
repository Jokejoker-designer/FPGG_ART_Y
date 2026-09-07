# ACCEPTANCE — U8-UNIFIED-SOC-XSIM-00 (qa-only)

```text
VERDICT   = PASS
OVERCLAIM = false
FRAUD     = false
SCOPE     = XSim of a7ng_typeclass_soc_chain from raw query
```

## Checks

- Raw bytes only; poke ports tied 0 in DUT.
- QSE 1,1,0,0 and heap 65,66,67 match U6 gold q=6.
- ENC==CTX; CLASS_ID 65/66/67 not in token stream.
- One LM busy-rise, one done, host=0.
- Glue is rtl `a7ng_lm_ctx_fwd_v1`, not bag copy, not `native_ctx_bind`.
- CLOSEOUT records SoC top **not** instantiated. pred=861 is not 653.

## Forbidden citations

BOARD_PASS · Gate14 · READY_TO_PROGRAM · production SoC already TYPE_CLASS ·
WDMA Root-B closed · U8R complete.
