# PREREG — G14-ROOT-B-TXN-AUDIT-00

```text
PROGRAM          = NO
GATE14_PASS      = NO
RTL_EDIT         = NO
UNKNOWN          = Can legal transaction sequencing still ACK without the intended architectural transition, after epoch is closed?
ROOT CAUSE       = not claimed (audit)
FALSIFIER        = board E0–E5 exact on 1F0F2ABB; or XSim showing ACK⇒commit and exactly-once WDMA under the active producer
EXPECTED         = ROOT_B verdict + maps; no patch treadmill
REGRESSION       = frozen oracle / epoch / TinyGPT untouched
```

Read-only. Bit `1F0F2ABB` is a historical BOARD artifact. Do not reprogram.
