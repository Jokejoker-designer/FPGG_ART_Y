# CLOSEOUT — U7P-PERSISTENCE-IDENTITY-00

```text
GATE                     = U7P-PERSISTENCE-IDENTITY-00
RESULT                   = PASS
EVIDENCE_CLASS           = XSIM
RTL_EDIT                 = NO
FLUSH_RELOAD_MATCH       = 1
SCHEMA_V2                = PASS (PERSIST-IDENTITY-SCHEMA-V2-00)
WIDTH_REPAIR             = SCHEMA_V2 (WIDTH-00 FAIL is historical)
U7_E8                    = E8_PERSIST_RELOAD_MATCH=1
U7_SIM_TIME_NS           = 281015
BIT                      = NO
PROGRAM                  = NO
GATE14_PASS              = NO
PERSIST_GEN_FAST         = DISCONNECTED (not repaired)
```

## Allowed claim

On the close-path `a7ng_learned_prior_store`, after QSE 30+30 and HEAPIFY
load/compare, U7 E8 still restores ranking after kill+reload
(`PERSIST_RELOAD_MATCH=1`). Schema V2 two-beat 32-bit identity remains
the frozen persist record. Store RTL was not edited this lake.

## Forbidden claims (not made)

silicon persist · persist_gen_fast repaired · SoC WDMA ACK=commit ·
BOARD_PASS · Gate14.

## NEXT

`U7A-ROOT-B-FINAL-00` — close-path store txn only. SoC WDMA Root-B stays
OPEN_AUDIT.
