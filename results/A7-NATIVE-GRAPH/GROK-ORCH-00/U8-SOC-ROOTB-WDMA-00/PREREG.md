# PREREG — U8-SOC-ROOTB-WDMA-00

```text
GATE              = U8-SOC-ROOTB-WDMA-00
STATUS            = OPEN (after P7 PASS)
PRIMARY_UNKNOWN   = on a SoC-reachable persist/WDMA path, do stall / eviction /
                    mid-txn reset / overflow / flush-reload preserve
                    ACK ⇔ one BRAM/DDR commit (no drop, no double-write)?
RTL_EDIT          = NO unless first divergence names one wire
SOC_TOP_EDIT      = NO
U8R               = NO
BIT               = NO
PROGRAM           = NO
```

Do not treat `persist_gen_fast` DISCONNECTED as repaired.
Do not use C7 observe-only as commit proof.
P7 TYPE_CLASS chain is not this unknown.
