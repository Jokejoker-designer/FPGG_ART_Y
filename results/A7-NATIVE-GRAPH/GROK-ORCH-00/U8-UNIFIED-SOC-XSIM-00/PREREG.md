# PREREG — U8-UNIFIED-SOC-XSIM-00

```text
GATE              = U8-UNIFIED-SOC-XSIM-00
STATUS            = OPEN
PRIMARY_UNKNOWN   = raw query bytes → QSE → U6 TYPE_CLASS retrieval →
                    encoder V1 → rtl a7ng_lm_ctx_fwd_v1 → LM-06
                    with FPGA-owned hierarchy (no TB poke of eid/iid)
DUT               = a7ng_typeclass_soc_chain (production-intent integrate)
NOT_DUT           = arty_a7_ng_native_v1_ab_soc_top (still u_bind=native_ctx_bind)
QUERY             = U6 q=6 "install chiller" (QSE 1,1,0,0 → heap 65,66,67)
RTL_EDIT          = YES (new integrate chain only)
SOC_TOP_EDIT      = NO
U8R               = NO
BIT               = NO
PROGRAM           = NO
QHEAD             = NO
SEMANTIC_LM       = MISMATCH
HOLD_A            = NO_RETARGET
SIM_FULL          = 1 (XSim LM forward only)
```

## Pass if

- Hierarchy instances: `u_u6` `u_enc` `u_fwd` `u_lm06` (not bag-local glue)
- QSE fields from raw bytes match U6 gold q=6
- Top-K CLASS_ID 65,66,67 then pads; CLASS_ID not serialized as LM token
- ENC stream == CTX pack stream
- One LM busy-rise, one done; glue pred == core pred
- Host cue/win/addr/tok/w = 0
- Stop at first divergence

## Fail if

TB pokes QSE fields. `native_ctx_bind` on this path. CLASS_ID/low8/NID as token.
SoC-top / MIG claimed. OUT=653 claimed. BOARD_PASS.

## Not this gate

U8R (remove synthetic from `a7ng_native_v1_ab_core`). WDMA stall matrix.
Full-chip SIM_FULL=0 impl. PROGRAM.
