# PREREG — C02-PRODUCTION-PATH-INTEGRATION-00

```text
GATE              = C02-PRODUCTION-PATH-INTEGRATION-00
UNKNOWN           = production ab_core has TYPE_CLASS→encoder/fwd on the
                    same TinyGPT as bind; UART soc_top still not feeding
                    raw query bytes (INTEGRATION_GAP residual)
BIT               = NO
PROGRAM           = NO
U9S               = NO
SOC_TOP_XSIM      = NO (MIG)
```

PLAN C02: one production path UART→QSE→retrieval→learn→encoder/fwd→single LM.
This revision puts QSE/U6/fwd on ab_core (`u_tc`) sharing `u_core`.
soc_top UART decoder remains Gate14 opcodes; not claimed closed.
