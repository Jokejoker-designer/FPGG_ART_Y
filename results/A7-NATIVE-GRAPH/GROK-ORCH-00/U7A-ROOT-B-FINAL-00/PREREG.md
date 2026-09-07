# PREREG — U7A-ROOT-B-FINAL-00

```text
GATE              = U7A-ROOT-B-FINAL-00
SCOPE             = close-path learned_prior_store txn
SOC_WDMA_ROOT_B   = OPEN_AUDIT (G14-ROOT-B-TXN-AUDIT-00, not this unknown)
RTL_EDIT          = NO
BIT               = NO
PROGRAM           = NO
```

Invariant: persist_done / c7_ack / ack_count only if BRAM wrote;
else persist_nak. U7A FAIL remains immutable. persist_gen_fast not repaired.
