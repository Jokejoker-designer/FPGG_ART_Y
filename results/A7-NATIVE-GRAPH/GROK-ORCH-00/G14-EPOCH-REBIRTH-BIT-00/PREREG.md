# PREREG — G14-EPOCH-REBIRTH-BIT-00

```text
PROGRAM = NO
GATE14_PASS = NO
```

Human approved epoch object (PR #8 merged `c773dc44`).

Fileset = C9-07 SoC + epoch law (`a7ng_pkg`, `a7ng_learned_prior_store`).
`persist_gen_fast` is **not** in the C9 SoC fileset.

Frozen oracle unchanged:

```text
HOLD_A C9=8382238122802120 OUT=653
UNREL  OUT=689
CONTRA OUT=237
HOLD_B OUT=60
```

Pre-impl XSim: `GATE14_C9_SOC_COFIT_XSIM_PASS fails=0` on this RTL.

Unique bit must not equal `3A7EF204` / `7ECCA0E2` / `A0B338E0`.

Human owns JTAG. This bag does not program the FPGA.

Impl blocked: see `BLOCKER.md`. Dummy PHYS shims were **reverted**.
