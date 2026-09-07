# PREREG — U6T-TYPECLASS-HEAP-TIMING-00

```text
GATE                 = U6T-TYPECLASS-HEAP-TIMING-00
BASE                 = 56e0e8e
PRIMARY_UNKNOWN      = post-route OOC WNS of U6 TYPE_CLASS heap at 100 MHz
CONTROL              = U6 synth-only WNS -4.103 ns (unplaced, HD.CLK_SRC unset)
RTL_EDIT             = NO unless post-route still WNS<0
BIT                  = NO
PROGRAM              = NO
HOLD_A               = not retargeted
```

First experiment: OOC synth+place+route of `a7ng_u6_typeclass_ooc_top`,
`create_clock -period 10` on `clk`, I/O false-path (measure internal heap).
No law change. Heap `beats()` / K=8 / SIFT_ON_TAKE=0 unchanged.

PASS iff post-route WNS>=0 and TNS=0 on clk, hold WHS>=0.

If FAIL: stop at first divergence (heap CE path); do not open U8R.
