# CLOSEOUT — G14-METRIC-PHYS16-00

```text
SILICON_PHYS     = 4
THIS_RUN_PHYS    = 16
LANE_UTIL        = 0.001766   MIG_XSIM
STALL            = 0
AXI_READ_B/Q     = 1024
ELIG             = 1699  (same as PHYS=4)
ACT_SUM          = 48    (same as PHYS=4)
PROGRAM          = NO
GATE14_PASS      = NO
```

16 PHYS lanes **do not** shorten the query. They dilute utilization 4×.
That is HS-09 / blueprint §11.4.3: lanes without extra feed = idle hardware.
