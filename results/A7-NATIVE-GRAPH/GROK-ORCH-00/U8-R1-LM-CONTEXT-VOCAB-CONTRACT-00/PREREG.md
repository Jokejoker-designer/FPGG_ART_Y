# PREREG — U8-R1-LM-CONTEXT-VOCAB-CONTRACT-00

Audit only. No encoder RTL. No TYPE_CLASS glue. No Q-head.

```text
GATE     = U8-R1-LM-CONTEXT-VOCAB-CONTRACT-00
HEAD     = 1bf9966b649361539ee16fb2b426514a83559a56
POLICY   = F_STAGED_FPGA_CONTEXT_ENCODER_V1
R0       = PASS 40bb05f
RTL_EDIT = NO
BIT      = NO
PROGRAM  = NO
```

Must inspect: tokenizer/vocab, size, token meanings, specials,
checkpoint provenance, embedding index, max ctx, LM-06 training ctx law.

Then freeze `LM_CTX_TYPECLASS_SERIAL_V1` SHA **or** classify
`LM_CHECKPOINT_CONTEXT_MISMATCH`.

Do not invent numeric vocab IDs. Do not bend serializer for OUT=653.
