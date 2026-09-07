# RESULTS — U8-R1

```text
RESULT = MEASURE_PASS
CLASS  = LM_CHECKPOINT_CONTEXT_MISMATCH
RTL    = NO
```

| Item | Finding |
|---|---|
| Vocab size | 1024 |
| Token meanings | none (opaque indices) |
| Specials | none safe in 8-bit |
| Tokenizer file | absent |
| Embedding | OFF_TOK + tok*D + dim; ctx_pack indexes 0..255 only |
| Max ctx | 128 core / 8 bind today / 1 confirmation |
| Checkpoint | `c204e55909d99370387c479c74e28c15f285fddee20239459d7c0ec3373001e0` |
| Trained ctx | `[1] → target 32` (not TYPE_CLASS) |
| Mapping table | EMPTY |
| Protocol SHA | `f88f6db7a73e25a6dfdb849bd781fac7a190a11b3964f234860de43829c4ed97` |

R2 encoder XSim must **not** start as a semantic LM claim.
Owner may later: (1) train a versioned checkpoint, or (2) authorize
**structural** encoder XSim explicitly labeled MISMATCH.
