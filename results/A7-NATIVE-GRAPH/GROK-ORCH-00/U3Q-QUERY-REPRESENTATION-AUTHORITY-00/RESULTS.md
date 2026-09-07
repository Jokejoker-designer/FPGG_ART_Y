# RESULTS — U3Q-QUERY-REPRESENTATION-AUTHORITY-00

```text
LAW         = qfe-v1-crc16-mix-00
RTL         = rtl/native_graph/query/a7ng_query_feature_extract.sv
SOC_WIRING  = NO
C9/ORACLE   = HOLD
BIT         = NO
PROGRAM     = NO
```

XSim:

| Query | Tokens | K0 | K1 | K2 | K3 |
| --- | --- | --- | --- | --- | --- |
| Q0 | 2,3,4 | B72B | B229 | 0D07 | B42E |
| Q1 | 2,3,5 | A70A | A308 | 0F06 | A40E |
| Q2 | 2,3,4 | B72B | B229 | 0D07 | B42E |
| Q3 | 8,1,9,2 | ACE9 | AEE1 | 160A | A8EB |
| Q4 | 8,1,9,3 | BCC8 | BFC0 | 160B | B8CB |

Q0==Q2. Q1≠Q0. No host hash/shard/bucket/winner/address ports.

`QUERY_REPRESENTATION_AUTHORITY_PASS`

Not wired into production SoC (slice 99.03%; one-unknown). Sparse router is U4A/U4.
