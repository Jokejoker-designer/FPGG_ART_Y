GATE: mem00
CHANGED: results/A7-NATIVE-GRAPH/MEM-00/BRAM_OWNERSHIP.md (classified 132 tiles)
WHY: HS-11 naive 180% BRAM; need ownership before integrate
TESTS: doc audit vs build/out/a7lm06_utilization_route.rpt + prior Q0
EXPECTED: A7NG_MEM00_BRAM_AUDIT_PASS; lever=DDR-back 01R/02M
ACTUAL: 66 act / 64 weight-stage / 2 snap; W2 insufficient alone
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/MEM-00/
SHA256: 79ECB936A15856D095D61F35B1E4DA5AC129B85E9DDCD37EA6CA5059FC9EDF3D
NEXT GATE: mem01_mem02
