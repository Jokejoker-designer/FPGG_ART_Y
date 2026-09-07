# RESULTS — U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00

```text
RESULT           = FAIL
FIRST_DIVERGENCE = NO_RIVAL_MEETS_U5Q_BAR
CHOSEN           = none
U7A              = CLOSED
```

Same U5Q gold and `THRESHOLDS.json`. No XOR tables. No nid keys.

## Meets U5Q bar at all 6 scales?

All nine profiles: **NO**.

## Snapshot N=256 (precision hole) and N=800k (scale hole)

| profile | leak prec@256 | water prec@256 | chiller rec@256 | chiller rec@800k |
|---------|---------------|----------------|-----------------|------------------|
| P4_4k_h64_c64 (control) | 0.05 | 0.281 | 0.853 | 0.0019 |
| P2_T02_4k_h64_c64 | 0.057 | 0.281 | 0.853 | 0.0019 |
| P2_T01_4k_h64_c64 | 1.00 | 0.281 | 0.693 | 0.0019 |
| P2_T02_8k_h128_c192 | 0.057 | 0.24 | 1.00 | 0.0056 |
| P4_4k_h128_c128 | 0.05 | 0.141 | 1.00 | 0.0038 |
| P4_4k_h256_c256 | 0.05 | 0.140 | 1.00 | 0.0075 |
| P4_8k_h64_c64 | 0.05 | 0.281 | 0.853 | 0.0019 |
| P4_4k_h64_c64_AND | 1.00 | 1.00 | 0.40 | 0.0009 |
| P2_T02_4k_h64_c64_AND | 1.00 | 0.60 | 0.40 | 0.0009 |

Unrelated (payroll) stays 0 cands on every profile.

AND intersection fixes leak/water precision, but chiller recall@256 falls below Master 0.80.
Deeper heads/caps improve 800k recall only in the third decimal and violate fraction/bytes bounds.

No silent CAND_CAP raise on control P4.
