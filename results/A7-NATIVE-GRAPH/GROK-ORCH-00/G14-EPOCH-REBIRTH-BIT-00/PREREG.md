# PREREG — G14-EPOCH-REBIRTH-BIT-00

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO
GATE14_PASS      = NO
REBUILD          = NO
RTL_EDIT         = NO
```

Human approved epoch object (PR #8 merged `c773dc44`) and this unique bit.

Fileset = C9-07 SoC + epoch law (`a7ng_pkg`, `a7ng_learned_prior_store`).
`persist_gen_fast` is **not** in the C9 SoC fileset.

Frozen oracle unchanged:

```text
HOLD_A C9=8382238122802120 OUT=653
UNREL  OUT=689
CONTRA OUT=237
HOLD_B OUT=60
```

Impl complete. Unique SHA
`1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9`.
Historical PHYS bind-drift blocker is superseded (`BLOCKER.md`).

Wording: one functional unknown = epoch object. `DELTA_FROM_3A7EF204.md`.

Human owns JTAG. This bag does not program the FPGA. Do not regenerate.
