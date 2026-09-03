# BLOCKER — unique bit not built

```text
PROGRAM = NO
READY_TO_PROGRAM = NO
GATE14_PASS = NO
FIRST_DIVERGENCE = FILESET_BIND_DRIFT
```

Epoch law is XSim-closed. Unique bitstream from **current main** is not a
one-unknown experiment against silicon `3A7EF204`.

## What is closed (XSim)

```text
GATE14_C9_SOC_COFIT_XSIM_PASS fails=0
HOLD_A C9=8382238122802120 OUT=653
UNREL  OUT=689
CONTRA OUT=237
HOLD_B OUT=60
```

That DUT is `a7ng_gate14_c9_soc_cofit_xsim` (learned graph + glue + TinyGPT).
It does **not** instantiate `a7ng_cue_soa_mig_top` / `a7ng_scorer_array`.

## What blocked impl

`synth_design` of `arty_a7_ng_native_v1_ab_soc_top` failed:

```text
1. a7ng_cue_soa_mig_top has no parameter PHYS
   overridden from a7ng_native_v1_ab_core.sv:148
   (ABCORE SHA still matches BIT-07; CUE SHA does not)

2. After a dummy PHYS shim on cue (reverted):
   a7ng_scorer_array has no parameter PHYS
   overridden from a7ng_ng02_core.sv:77
```

BIT-07 SOURCE_SHA vs this tree also drifted on TinyGPT, cue, heap, wavefront,
AOS boot. Dummy-`PHYS` on every drifted module is the patch treadmill.

## What a unique bit is allowed to be

Same fileset as fail bit `3A7EF204` **except** epoch store/pkg.
That is not this worktree as it sits. Do not implement a mixed bit.

Do not program the FPGA.
