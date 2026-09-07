# CLOSEOUT — U8-R3-TYPECLASS-TOPK-TO-LM-00

```text
GATE                     = U8-R3-TYPECLASS-TOPK-TO-LM-00
HEAD                     = 4ca071e7927aa4ceb6b9868eb17630ffa985eaf0
ENCODER                  = rtl/native_graph/lm/a7ng_lm_ctx_encoder_v1.sv
ENCODER_SHA256           = bbd95f7f148e722002e1982292662c8cb54e26ce16ff7ead75400313182892aa
ENCODER_EDIT             = NO
GLUE                     = a7ng_lm_ctx_fwd_v1 (bag+rtl identical; not native_ctx_bind)
RESULT                   = PASS
SCOPE                    = unified Top-K CLASS_ID → encoder → LM-06 XSim
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
EVIDENCE                 = XSIM + RTL_FACT
MARKER                   = U8_R3_TYPECLASS_TOPK_TO_LM_PASS

HEAP                     = 65,66,67 + pads (U7 ranking DUT topk_class_id_o)
STREAM                   = rank-order [eid,iid,rid,xid]
CLASS_ID_AS_TOKEN        = NO
LOW8_CLASS_ID            = NO
MEMBER_NID               = NO
BIND_LOW8                = NO
CTX_WE_BEATS             = 2
START_FWD_PULSES         = 1
LM_BUSY                  = 1
LM_DONE                  = 1
HOST_SEMANTIC            = 0

BIT                      = NO
PROGRAM                  = NO
QHEAD                    = NO
HOLD_A_ORACLE_RETARGET   = NO
```

SEMANTIC_LM_CLAIM=NO CLASS=LM_CHECKPOINT_CONTEXT_MISMATCH BIT=NO PROGRAM=NO QHEAD=NO

## Allowed claim

In XSim, U7 ranked TYPE_CLASS CLASS_ID heap feeds encoder V1; encoder
emits rank-order eid/iid/rid/xid ctx_we beats; LM-06 SIM_FULL accepts
one start_fwd and completes one done; host tok/w/win/addr stay 0.

## Forbidden claims (not made)

LM understands TYPE_CLASS · unified production silicon glue · Gate14 ·
OUT=653 · Q-head · new checkpoint

## NEXT (do not auto-open)

Not U8R. Not U9. Not Q-head. Semantic claim stays mismatch until a new
checkpoint is trained on `LM_CTX_TYPECLASS_SERIAL_V1`.
