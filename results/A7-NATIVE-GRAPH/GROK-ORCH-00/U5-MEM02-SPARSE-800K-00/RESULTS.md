# RESULTS — U5-MEM02-SPARSE-800K-00

```text
XSIM = U5_MEM02_SPARSE_800K_PASS
```

Host-model ladder N={42,256,4096,16384,65536,262144,800000}:

- SPREAD (extra records in unprobed buckets): chiller bytes=64 constant, emit=4
- COLLIDE (same probed buckets): saturates at HEAD_CAP=64 / CAND_CAP=64; 800k bytes == 65k bytes

XSim:

| Case | dir | emit | trunc | bytes | note |
|------|-----|------|-------|-------|------|
| QSE chiller + 256 T3 dummies | 2 | 4 | 0 | 64 | no T3 AR |
| poke sentinel | 1 | 1 | 0 | — | id=`c34ff` post=`0x05060000` |
| poke collide 200 | 1 | 64 | 136 | 816 | cap exact |
| unknown | 0 | 0 | 0 | 0 | no scan |
