# CLOSEOUT — U8-R2-LM-CONTEXT-ENCODER-V1-00

```text
GATE                     = U8-R2-LM-CONTEXT-ENCODER-V1-00
HEAD_BEFORE              = 63e862a62578949066c4f84ac180d6a55a777aee
RTL                      = rtl/native_graph/lm/a7ng_lm_ctx_encoder_v1.sv
RESULT                   = PASS
SCOPE                    = structural encoder XSim
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH (carried)
EVIDENCE                 = XSIM + RTL_FACT
MARKER                   = U8_R2_LM_CONTEXT_ENCODER_V1_PASS

UNIQUE_EIRX              = 443/443
STREAM                   = rank-order [eid,iid,rid,xid] per valid CLASS_ID
CLASS_ID_AS_TOKEN        = NO
LOW8_CLASS_ID            = NO
MEMBER_NID               = NO
QHEAD                    = NO
BIT                      = NO
PROGRAM                  = NO
HOLD_A_ORACLE_RETARGET   = NO
```

## XSim

| Test | Result |
|---|---|
| install 65,66,67 → 12 tokens `1,1,0,0,1,1,0,1,1,1,1,0` | OK |
| chiller 57–64 ntok=32 | OK |
| CLASS 1 vs 257 distinct | OK (257 → `7,0,2,0`) |
| CLASS 256,427 (>255) | OK |
| pads only ntok=0 | OK |
| CLASS 0 skipped | OK |
| CLASS 443 | OK |

## Allowed claim

FPGA-owned encoder serializes ranked TYPE_CLASS descriptors into an
8-bit token stream without CLASS_ID/low8/member-NID, in XSim.

## Not claimed

LM understands the stream · unified Top-K→LM · OUT=653 · silicon
