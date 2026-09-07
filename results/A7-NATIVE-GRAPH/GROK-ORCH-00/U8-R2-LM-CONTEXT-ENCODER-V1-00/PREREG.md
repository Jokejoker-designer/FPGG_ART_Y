# PREREG — U8-R2-LM-CONTEXT-ENCODER-V1-00

Owner: continue after R1. Structural encoder only.

```text
GATE     = U8-R2-LM-CONTEXT-ENCODER-V1-00
HEAD     = 63e862a62578949066c4f84ac180d6a55a777aee
POLICY   = F_STAGED_FPGA_CONTEXT_ENCODER_V1
SEMANTIC = LM_CHECKPOINT_CONTEXT_MISMATCH  (unchanged)
RTL_EDIT = YES (encoder module only)
QHEAD    = NO
BIT      = NO
PROGRAM  = NO
HOLD_A_ORACLE_RETARGET = NO
```

## Encoding (FPGA-owned)

Measured: 443/443 TYPE_CLASS rows have unique `(eid,iid,rid,xid)`.
CLASS_ID is recoverable from that tuple. Therefore V1 does **not**
serialize CLASS_ID as tokens (16-bit; low8 forbidden).

Per ranked valid CLASS_ID, FPGA materializes the frozen row and emits:

```text
tok += [eid, iid, rid, xid]
```

Rank order = heap order. Pads / CLASS_ID 0 / miss skipped.
`ntok = 4 * N_VALID`. Max 32 for K=8.

Prereg install-chiller 65,66,67:

```text
65 → 1,1,0,0
66 → 1,1,0,1
67 → 1,1,1,0
stream = 1 1 0 0  1 1 0 1  1 1 1 0
ntok = 12
```

Host does not supply eid/iid/rid/xid/token.

## Not this gate

LM-06 forward · unified Top-K→LM (that is R3) · OUT=653 · Q-head
