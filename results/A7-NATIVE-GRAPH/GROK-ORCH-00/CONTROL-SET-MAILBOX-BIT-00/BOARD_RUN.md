# CONTROL-SET-MAILBOX-BIT-00 — board FAIL 2026-08-31 04:37

**PROGRAM_DONE then FAIL.** Do not freeze this SHA as existence. Restore `B0F42C11`.

```text
BOOT
MIG_OK
WMEM_OK
TOPK=0000000000000000
PACK=0000000000000000
POISON=0
CORE_DONE
NATIVE_V1_EXIST_ROW,pred=249
```

| Field | Value |
|-------|--------|
| SHA | `582F9E47…` |
| JTAG | `210319BE776EA` HIGH |
| TOPK/PACK vs A-FAST | **0** FAIL |
| pred | **249 ≠ 664** FAIL |
| BOARD_PASS | not_claimed |

Mailbox sequential/BRAM write **broke** G_(t) / bind pack. Hypothesis slice-save is not a causal existence successor.

**Restore 04:38:** reprogrammed `B0F42C11`. UART `TOPK=PACK=3B392B291B190B09` `pred=664` again. Board is back on the existence successor.
