# RESULTS — G14-EPOCH-REBIRTH-BIT-00

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO
GATE14_PASS      = NO
BOARD_PASS       = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
REBUILD          = NO
RTL_EDIT         = NO
```

Unique bit (not `3A7EF204` / `7ECCA0E2` / `A0B338E0`):

```text
SHA256=1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
path=arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
```

Impl gates:

```text
WNS=0.373 TNS=0 WHS=0.008 THS=0
ramb36=104 dsp=19 lut=35917 ff=44164
slice=15581/15850 free=269
cdc_cand=0 persist_crit=0 nstd1=0 ucio1=0 route_err=0
FIRST_DIVERGENCE=NONE
gate_pass=1
```

Pre-impl XSim on this fileset (BIT-07 TinyGPT `75706E2C` + epoch store):

```text
GATE14_C9_SOC_COFIT_XSIM_PASS fails=0
C9  A/U/C/B = 8382238122802120 / 8786858483828180 / 2322832182208180 / 8382438142804140
OUT A/U/C/B = 653 / 689 / 237 / 60
```

Wording: **one functional unknown = epoch object** (STORE+PKG), not
“only one file differs.” SHA-delta classes: `DELTA_FROM_3A7EF204.md`.

Freeze: no cleanup, no extra probe, no RTL merge, no regenerate. Free
slices ~1.7%. Extra instrumentation can move placement.

Human owns JTAG. Do not program from this agent. Protocol in
`HUMAN_PROGRAM_TOKEN.md`.
