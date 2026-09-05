# RESULTS — U7A-ROOT-B-REACHABILITY-REAUDIT-00

```text
RESULT = REAUDIT_COMPLETE
TYPECLASS_XSIM_COMPLETION = CONFIRMED
SOC_ROOT_B                = PARTIALLY_CONFIRMED (unchanged)
U7_OPEN                   = NO
```

Evidence: RTL walk of `a7ng_u6_typeclass_retrieval.sv` + reused
`U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS` (134665 ns). No new XSim. No RTL edit.

U6 `done_o` is a 1-cycle strobe on the same posedge as the last Top-K
CLASS_ID latch (`hp_idx==K-1`). Overflow/trunc are latched at walk complete,
before pad/drain. Scanner-done alone cannot raise `done_o`.

SoC bit `1F0F2ABB` does not contain this module. Historical Root-B
ACK≠commit / missing txn object remains. `C7_ADDR` stays OBSERVE_ONLY.
