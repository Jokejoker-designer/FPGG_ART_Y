# CLOSEOUT — G14-METRIC-MEASURE-01

```text
RTL_EDIT     = NO
BIT          = NO
PROGRAM      = NO
M10          = KEEP_OPEN

P3_LANE_UTIL = 0.007063  MIG_XSIM  PASS
P4_DDR_STALL = 0 cycles  MIG_XSIM  PASS
M7_BYTES/Q   = 1024 SOA / 0 C9-exam
               MIG_XSIM + XSIM     PASS
M10_800K     = KEEP_OPEN           OPEN

OPEN_METRIC_BEFORE = 4
OPEN_METRIC_AFTER  = 1
GATE14_PASS        = NO
```

H_CANDIDATE **SUPPORTED** for P3/P4/M7 (measured, not invented).
M10 remains OPEN by lock.

Stub AXI XSim hung at 32/64 (`ng02` ST_PUSH). MIG completed 64/64; that is
the P3/P4/M7 SOA authority.

Do not program. Do not treat stall=0 as “no DDR”. It is a counted zero.
