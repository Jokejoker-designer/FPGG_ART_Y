# PREREG — U7A-ROOT-B-REACHABILITY-REAUDIT-00

```text
GATE            = U7A-ROOT-B-REACHABILITY-REAUDIT-00
BASE            = 6438184c64aa063c10e46865c94049eb48d37406
RTL_EDIT        = NO
BIT             = NO
PROGRAM         = NO
REPROGRAM_AGAIN = NO
U7              = CLOSED (not opened by this reaudit)
U8              = CLOSED
GATE14_PASS     = NO
```

PRIMARY_UNKNOWN:

After TYPE_CLASS became the production retrieval identity on the U6
XSim object, does SUCCESSFUL COMPLETION still mean the intended
architectural state transition is committed (CLASS_ID Top-K + overflow
latched), or can completion fire without that commit (Root-B ACK≠commit
re-introduced at the new identity)?

Two objects must not be merged:

1. U6 typeclass XSim top (`a7ng_u6_typeclass_retrieval`)
2. Gate14 SoC bit `1F0F2ABB` (learned_prior_graph / TinyGPT WDMA)

Historical G14-ROOT-B-TXN-AUDIT-00 remains `ROOT_B_PARTIALLY_CONFIRMED`.
This gate re-audits reachability under the new identity. No patch treadmill.
