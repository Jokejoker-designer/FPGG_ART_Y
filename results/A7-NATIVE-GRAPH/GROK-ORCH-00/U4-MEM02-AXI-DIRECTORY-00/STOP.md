# STOP — U4-MEM02-AXI-DIRECTORY-00 BEFORE INTEGRATION

```text
GATE            = U4-MEM02-AXI-DIRECTORY-00
STATE           = OPEN_NOT_INTEGRATED
REASON          = PRE0 geometry PASS; extractor path not yet wired
PRE0            = PASS ROUTER_TO_AXI_GEOMETRY_COMPATIBILITY
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U5              = CLOSED
GATE14_PASS     = NO
EXTRACTOR_WIRE  = NO
SOC             = NO
```

Do not wire U3Q extractor → AXI directory until PRE0 PASSes
`ROUTER_TO_AXI_GEOMETRY_COMPATIBILITY`.

Legacy mismatch (must not be treated as MEM02):

```text
N_TABLES default  = 2     (authority 4)
N_BUCKETS default = 16    (authority 4096)
CAND_CAP default  = 32    (authority 64)
ports             = k0,k1 only
key_of(t>=2)      = k0 ^ k1 ^ table   FORBIDDEN synthetic
dir_addr          = k_use[B_W-1:0] with B_W=4 aliases 12-bit keys
```
