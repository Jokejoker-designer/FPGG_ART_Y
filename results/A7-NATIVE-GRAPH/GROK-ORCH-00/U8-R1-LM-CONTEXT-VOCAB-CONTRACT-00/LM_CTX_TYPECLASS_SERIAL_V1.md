# LM_CTX_TYPECLASS_SERIAL_V1

```text
LAW_ID = lm-ctx-typeclass-serial-v1
SHA256 = f88f6db7a73e25a6dfdb849bd781fac7a190a11b3964f234860de43829c4ed97
FILE   = LM_CTX_TYPECLASS_SERIAL_V1.json
```

This SHA freezes the **protocol grammar**, not a CLASS_ID→token table.

## Grammar (FPGA-owned, rank-order preserving)

For each valid Top-K TYPE_CLASS in heap order:

```text
descriptor = { CLASS_ID[15:0], eid[7:0], iid[7:0], rid[7:0], xid[7:0] }
```

V1 does **not** add rank, prior, confidence, or conflict.

Transport: 8-bit LM tokens, multi-beat `ctx_we` allowed.
Proposed max ntok = 64 (≤ core C=128). Current bind ntok=8 is a **later R2
bind change**, not this audit.

## Mapping table

```text
LM_CTX_TYPECLASS_SERIAL_V1_MAPPING = EMPTY
```

Numeric encoding of CLASS_ID is **not defined**. Filling it would be
inventing vocab IDs. Owner forbade that in R1.

## Semantic compatibility

```text
LM_CHECKPOINT_CONTEXT_MISMATCH
```

Checkpoint `c204e559…3001e0` / law `lm06-signsgd-v1` was trained on
confirmation ctx=`[1]` (and C9 overlay uses NID-low8). It does **not**
interpret TYPE_CLASS descriptors.

Do not claim semantic LM compatibility. Do not retarget HOLD_A OUT=653.
