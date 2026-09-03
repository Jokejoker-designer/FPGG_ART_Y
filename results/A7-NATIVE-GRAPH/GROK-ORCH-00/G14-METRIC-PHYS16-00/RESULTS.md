# RESULTS — G14-METRIC-PHYS16-00

Parameter experiment only. **Silicon bit `F24150BD` remains PHYS=4.**
HS-09: do not claim 16 physical lanes on the programmed board.

```text
RTL_EDIT  = NO
BIT       = NO
PROGRAM   = NO
GATE14_PASS = NO
```

## MIG_XSIM complete 64-cand query (authority)

| | PHYS=4 (MEASURE-01) | PHYS=16 (this run) |
|--|--:|--:|
| delivered | 64 | 64 |
| waves | 4 | 4 |
| AXI read bytes | 1024 | 1024 |
| empty_stall | 0 | 0 |
| r_backpressure | 0 | 0 |
| FIRE cycles | 12 | 3 |
| ACT_SUM | 48 | 48 |
| ELIG | 1699 | 1699 |
| **lane_util** | **0.007063** | **0.001766** |

`0.007063 / 4 = 0.001766`. Same 48 lane-cycles of work, 4× more lanes → util ÷4.
ELIG unchanged: **DDR/query time did not improve.** 16 lanes sit idle.

```text
PHYS16_LANE_UTIL     = 0.001766
PHYS16_STALL         = 0
PHYS16_AXI_READ_B/Q  = 1024
evidence_class       = MIG_XSIM
artifact_sha         = 9876C2A28D1DCC9BFC6492BBE5155897B83A9AD5C1486E31A45172AF8DD19BE0
```

Stub XSim still hung at 32/64 (`ng02` ST_PUSH). Prefix: FIRE=1 ACT=16 ELIG=228 util=0.004386.
Not used as the complete-query number.

## Claims refused

- 16 lanes on `F24150BD`
- 16× throughput
- BOARD evidence for PHYS=16
