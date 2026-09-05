# NEXT — after U7 PASS (XSim, DEPTH=32 working set)

Q-head is **not** opened by this gate.

## Baseline metrics (report first)

- Causal rank flip on tied install-chiller 65/66/67: YES
- Context isolation CLASS_ID 58 chiller vs water: YES
- Freeze / zero / shuffle / held-out / persist: YES
- Duplicate exactly-once / store-full NAK: YES
- Host semantic = 0
- Store horizon: 32 unique TYPE_CLASS×QUERY_CONTEXT keys, NAK at write 33
- ~6 distinct queries with K=8 consume the working set

## Architecture decision (owner)

**A.** Baseline contextual prior (LEARN_KEY_CLASS_CONTEXT_V1 + scalar G1/G2)
is sufficient for the next product step.

**B.** Open Q-head / shared-weight learner as an **explicit rival**
after this baseline is frozen. Not a silent replacement.

## Carry OPEN

```text
U6_TYPECLASS_MINHEAP_TIMING = OPEN
WNS                         = -4.103 ns OOC
LEARN_STORE_CAPACITY_32     = OPEN HIGH_RISK_ARCHITECTURAL_HAZARD
persist_gen_fast            = DISCONNECTED (unpatched)
C7_ADDR                     = OBSERVE_ONLY
BIT                         = NO
PROGRAM                     = NO
REPROGRAM_AGAIN             = NO
QHEAD                       = NO
```
