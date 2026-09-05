# RESULTS — U4-PRE0-SPARSE-DIR-GEOMETRY-AUTHORITY-00

```text
HOST_MODEL  = PASS  4*4096=16384 unique dir_addr, disjoint T0..T3
XSIM        = U4_PRE0_SPARSE_DIR_GEOMETRY_PASS
U4R2        = U4_R2_DDR_SPARSE_DIRECTORY_PASS (protocol still pass)
U4_SEMANTIC = NO
BIT         = NO
PROGRAM     = NO
```

| # | Invariant | Result |
|---|-----------|--------|
| 1 | exact k0..k3 | PASS T2 AR=`0x05020CC0` = k2 bucket, not XOR |
| 2 | no synthetic keys | PASS XOR fake `0x05020130` not used |
| 3 | 12-bit bucket identity | PASS |
| 4 | disjoint table ranges | PASS T0=`0x05000000` T1=`0x05010000` T2=`0x05020000` T3=`0x05030000` last=`0x0503FFF0` |
| 5 | valid bits control probe | PASS valid=0 → 0 dir AR (key=0 and key!=0) |
| 6 | valid=1,key=0 | PASS T2 AR=`0x05020000` bucket 0 |
| 7 | low-4-bit alias eliminated | PASS `0x001`→`0x05000010` `0x011`→`0x05000110` (old16 both `0x05000010`) |
| 8 | CAND_CAP bounded | PASS emit=64 trunc=16 on 80 postings |
| 9 | no full scan | PASS unknown dir_ar=0; cap test dir_ar=1 not 4096 |
| 10 | U4-R2 protocol | PASS |

Directory law used by RTL:

```text
dir_addr = INDEX_BASE + table_id * 65536 + (k[11:0]) * 16
```
