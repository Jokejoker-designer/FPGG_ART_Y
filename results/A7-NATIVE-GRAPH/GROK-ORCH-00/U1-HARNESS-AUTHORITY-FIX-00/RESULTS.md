# RESULTS — U1-HARNESS-AUTHORITY-FIX-00

```text
RTL_EDIT    = NO  (DUT frozen)
TB_EDIT     = YES canonical MIG harness
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = OPEN
evidence    = MIG_XSIM
```

Canonical law now holds:

```text
any SOA_PATTERN_FAIL => FAIL
cell_fail = 0
N=64 AOS = 1024 B / 64 beats
merge_done = 4  (wave completion)
ordered_valid = 1 (may be after running=0)
```

| Check | Result |
| --- | --- |
| SOA_PATTERN | **PASS** |
| cell_fail | **0** |
| bytes / beats | **1024 / 64** |
| data_mismatch | **0** |
| merge_done | **4** |
| ordered_valid | **1** (running=0) |
| SOA_TOP1 | **id=9 score=165** |
| T_QUERY | **275** |
| II_STEADY | **40** |
| SORT_FINAL | **PASS** |
| DDR_WAVE_PINGPONG | **PASS** |
| HARNESS_AUTHORITY | **PASS** |

Legacy 832/52 and “4th pulse” capture are gone. Legacy SCORE_LAW id=57
is not the AOS golden control. New AOS-schema top1 is **9/165**.

DUT production RTL unchanged.
