# RESULTS — U4-MEM02-AXI-DIRECTORY-00

```text
XSIM = U4_MEM02_AXI_DIRECTORY_PASS
HOST = GOLDEN.json matches U4A-R6 candidate sets on the 6 corpus queries
```

| Q | Stimulus | dir | post | predup | emit | dup | trunc | beats | bytes |
|---|----------|-----|------|--------|------|-----|-------|-------|-------|
| 0 | QSE chiller | 2 | 2 | 8 | 4 | 4 | 0 | 4 | 64 |
| 1 | QSE water chiller | 3 | 3 | 27 | 22 | 5 | 0 | 10 | 160 |
| 2 | QSE leak chiller | 3 | 1 | 4 | 4 | 0 | 0 | 4 | 64 |
| 3 | QSE payroll tax form | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 4 | QSE soccer match score | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 5 | QSE adversarial | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 6 | poke one table | 1 | 1 | 4 | 4 | 0 | 0 | 2 | 32 |
| 7 | poke valid=1,key=0 | 1 | 1 | 1 | 1 | 0 | 0 | 2 | 32 |
| 8 | poke empty posting | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 16 |
| 9 | poke CAND_CAP 80 | 1 | 1 | 80 | 64 | 0 | 16 | 21 | 336 |
| 10 | poke all valid=0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 11 | poke valid=0,key!=0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 12 | QSE chiller + backpressure | 2 | 2 | 8 | 4 | 4 | 0 | 4 | 64 |

Cuts A–F matched on every query. Directory AR ≤ valid tables ≤ 4. No 0..N scan. Q3/Q4/Q5/Q10: unknown → 0 candidates, 0 dir AR.

Q9: emit=64 trunc=16, AXI drained (21 beats). Q12: cand_ready stall held presented beat.
