# RESULTS — U4A-R3-STRUCTURED-QUERY-ROUTER-00

```text
VERDICT = PASS
LAW     = qse-v1-lexicon-hdc-00 unchanged
GOLD    = independent entity labels
R16     = 0.952 >= 0.80
R64     = 0.952 / 1.0 >= 0.85
TAUTOLOGY = NO
CRC_ROUTE = NO
U5/BIT/PROGRAM/COM12 = CLOSED
```

P2 scale coverage fails because structured `k0={eid,iid}` is low-cardinality
at 800k. P4 adds k2/k3 occupancy. Pareto **P4_4k_h64 / CAND_CAP=64**, not 256.
