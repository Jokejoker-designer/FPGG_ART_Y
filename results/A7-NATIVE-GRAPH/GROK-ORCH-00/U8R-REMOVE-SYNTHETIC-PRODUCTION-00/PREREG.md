# PREREG — U8R-REMOVE-SYNTHETIC-PRODUCTION-00

```text
GATE              = U8R-REMOVE-SYNTHETIC-PRODUCTION-00
UNKNOWN           = production SoC hierarchy uses SYNTHETIC_CAND_GEN=0
                    so Gate14 cand_* walk is not the C9 source
FIXTURE           = default SYNTHETIC_CAND_GEN=1 (sim / HOLD_A)
RTL_EDIT          = YES (parameter + C9 mux; persist graph remains)
BIT               = NO
PROGRAM           = NO
```

One production retrieval for C9 IDs: parent `graph_id_i` (SOA / TYPE_CLASS).
`cand_nid` query walk gated off. Learned store persist stays for flush/reload.
