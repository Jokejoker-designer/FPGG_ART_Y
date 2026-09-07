# CLOSEOUT — U6Q-QSE-LEXICON-TIMING-00

```text
GATE                 = U6Q-QSE-LEXICON-TIMING-00
RESULT               = PASS
EVIDENCE_CLASS       = POST_ROUTE_OOC
FIRST_DIVERGENCE     = none
CLK                  = 10.000 ns (100 MHz, production)
ROUTE_WNS            = +0.163 ns
ROUTE_TNS            = 0.000 ns
ROUTE_WHS            = +0.132 ns
FAILING_EP           = 0 (setup) / 0 (hold)
LUT                  = 4395 / 63400 (6.93%)
FF                   = 1181 / 126800 (0.93%)
DSP                  = 0
RTL_EDIT             = YES (QSE 30+30 match pipeline + HEAPIFY load/compare)
LAW                  = qse-v1-lexicon-hdc-00 UNCHANGED
BEATS_LAW            = UNCHANGED
SPLIT                = QSE_SPLIT=30  (scan 0..29 then 30..59)
EXTRA_CYCLES         = +2 per word flush (ST_M0, ST_M1) then ST_AP apply
U3Q_XSIM             = PASS (U3Q_R3_XSIM_PASS)
U6_XSIM              = PASS (U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS)
BIT                  = NO
PROGRAM              = NO
GATE14_PASS          = NO
SOC                  = NO
BOARD                = NO
```

## What closed

Post-route OOC of `a7ng_u6_typeclass_ooc_top` meets the 10 ns internal
register-to-register constraint: WNS≥0, TNS=0, WHS≥0. I/O ports are
false-pathed (same recipe as U6T). Lexicon first-hit then min-id within
class is unchanged. Empty-wbuf fire still publishes accumulated ids.
`beats()` is unchanged.

QSE SHA256 = `B52443CD90AB02193C524BF11C02B17112F8339EF6F5FAD827B072553B1F8EBB`
HEAP SHA256 = `2803E2A33C0F42B8354F6825BEC797D5486D5EF1C9A4309B92E71828E9DB04EC`

## What this is not

- Not full-chip SoC timing.
- Not a bitstream.
- Not BOARD_PASS / Gate14 / U8R / U9 / PROGRAM.
- HD.CLK_SRC on OOC `clk` is unset (Vivado warning Timing 38-242 /
  Route 35-197). Slack is an OOC estimate without top-level clock-buffer
  placement.

## NEXT

`U7C-LEARN-STORE-LIMIT-00` — freeze DEPTH=32 as Native V1 close LIMIT.
Not SCALE to 800k. Not U8R. Not PROGRAM.
