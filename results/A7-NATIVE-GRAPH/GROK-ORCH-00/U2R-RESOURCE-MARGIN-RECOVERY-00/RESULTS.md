# RESULTS — U2R-RESOURCE-MARGIN-RECOVERY-00

```text
EVIDENCE     = POST_ROUTE  (e2r_post_route.dcp, PROGRAM=NO, SKIP_BITSTREAM)
PARSER       = Available-column  used=15537 tot=15850 free=313
U2_BASELINE  = used=15697 tot=15850 free=153
DELTA_FREE   = +160 slices
TIMING       = WNS=1.126 TNS=0 WHS=0.014 THS=0 route_err=0
RAMB36       = 106  (U2=104; +2 snap_ram4k16 BRAM)
DSP          = 19
SNAP         = BRAM  u_snap/mem_reg 4K×16  RAMB36=2  LUTRAM_BIND=NO
LOGITS       = still LUTRAM 704  (not this unknown)
PREFERRED800 = OPEN  (313 < 800)
HARD_FIT     = PASS  (free 313 >= 64, timing close, C9 SHA BIND=C5F57AD1)
PHYS         = 4
BIT          = NO
PROGRAM      = NO
```

Snap LUTRAM (U2 hier 1408 LUT) is gone; logits LUTRAM remains the packing
squeeze. Do not open U5 on 313 free slices.
