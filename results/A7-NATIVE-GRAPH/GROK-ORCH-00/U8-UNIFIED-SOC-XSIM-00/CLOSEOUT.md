# CLOSEOUT — U8-UNIFIED-SOC-XSIM-00

```text
GATE                     = U8-UNIFIED-SOC-XSIM-00
RESULT                   = PASS
EVIDENCE_CLASS           = XSIM
FIRST_DIVERGENCE         = none
DUT                      = a7ng_typeclass_soc_chain
HIERARCHY                = u_u6 → u_enc → u_fwd → u_lm06
QUERY                    = raw "install chiller" (15 bytes; no poke)
QSE                      = eid=1 iid=1 rid=0 xid=0
HEAP_CLASS_ID            = 65 66 67 + pads
ENC_CTX_STREAM           = 1 1 0 0 1 1 0 1 1 1 1 0
CTX_WE_BEATS             = 2
START_FWD_PULSES         = 1
LM_BUSY_RISE             = 1
LM_DONE                  = 1
PRED_OBS                 = 861
HOST_SEMANTIC            = 0
CLASS_ID_AS_TOKEN        = NO
NATIVE_CTX_BIND          = NOT on this path
SOC_TOP                  = NOT instantiated
MIG                      = NOT instantiated
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
BIT                      = NO
PROGRAM                  = NO
QHEAD                    = NO
U8R                      = NO
HOLD_A_ORACLE_RETARGET   = NO
MARKER                   = U8_UNIFIED_SOC_XSIM_PASS
```

## Allowed claim

From raw application bytes (not TB-poked fields), FPGA QSE + U6 TYPE_CLASS
retrieval produces CLASS_ID heap 65/66/67; production `a7ng_lm_ctx_fwd_v1`
forwards encoder `{eid,iid,rid,xid}` beats into LM-06; context matches
encoder; one start/done; host winner/token counters stay 0. XSim.

## Not claimed

`arty_a7_ng_native_v1_ab_soc_top` still uses `a7ng_native_ctx_bind` (P8).
WDMA stall/evict/reset/overflow ACK=commit matrix not run (P7b).
OUT=653 / Gate14 / BOARD_PASS / silicon.

## NEXT

P7b `U8-SOC-ROOTB-WDMA-00` — persist/WDMA txn on a SoC-reachable path.
Then P8 U8R (remove synthetic / NID bind from production top). Not PROGRAM.
