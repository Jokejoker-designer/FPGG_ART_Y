# PREREG — G14-TEACHER-OFF-NATIVE-CAUSALITY-00

```text
PROGRAM          = NO
GATE14_PASS      = NO
RTL_EDIT         = NO
HS-25            = Gate T (host-off → native retrieval → C9)
UNKNOWN          = With host semantic assistance cut, does the FPGA emit oracle HOLD_A C9 from learned state?
ROOT CAUSE       = not claimed
FALSIFIER        = HOLD_A C9 != 8382238122802120 while n_host_*=0, learn=0, freeze=1
EXPECTED         = C9 exact; OUT observed not scored
REGRESSION       = frozen oracle C9; no LM-law change
```

LM-06 active chain is **Gate L**, not this gate. If C9 fails, stop at retrieval.
