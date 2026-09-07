# PREREG — U8-R0-LM06-ACTIVE-CHAIN-ON-FROZEN-C9-00

Before XSim. Owner lock: `F_STAGED_FPGA_CONTEXT_ENCODER_V1`.

```text
GATE     = U8-R0-LM06-ACTIVE-CHAIN-ON-FROZEN-C9-00
HEAD     = d6a77f2a37d728bfc9d03dd55f9ce939a9001e76
POLICY   = F_STAGED_FPGA_CONTEXT_ENCODER_V1
DUT      = a7ng_gate14_c9_soa_lm_xsim   (legacy C9 graph + bind + LM-06)
RTL_EDIT = NO
TYPECLASS_GLUE = NO
QHEAD    = NO
BIT      = NO
PROGRAM  = NO
```

## Purpose (only)

Prove already-wired legacy chain:

```text
legacy C9 Top-8
→ ctx_we exactly once
→ start_fwd accepted (one LM forward)
→ LM busy
→ LM done exactly once
→ pred FPGA-owned (core_pred → bind → C10)
```

Host:

```text
n_host_tok = n_host_w = n_host_win = n_host_addr = 0
```

## HOLD_A (immutable regression evidence, not this gate's oracle)

```text
HOLD_A C9 = 8382238122802120
OUT       = 653 / 689 / 237 / 60
```

R0 may **observe** C9/OUT. R0 must **not** retarget them.
Untrained graph pack/OUT may differ from HOLD_A; that is not a fail.

## start_fwd pulse law (frozen bind H4)

`a7ng_native_ctx_bind` may re-pulse `start_fwd` until TinyGPT leaves IDLE.
Grade:

- `ctx_we_beats == 1`
- `core_busy` rises once
- `core_done` once
- `start_fwd` pulses >= 1
- two LM forwards = FAIL

Do not treat H4 re-issue as a second exam.

## Not claimed

TYPE_CLASS→LM · LM_CONTEXT_ENCODER_V1 · new oracle · Q-head · silicon · Gate14
