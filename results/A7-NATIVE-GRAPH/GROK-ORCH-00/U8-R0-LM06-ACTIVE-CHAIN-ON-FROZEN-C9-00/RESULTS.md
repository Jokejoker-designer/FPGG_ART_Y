# RESULTS — U8-R0-LM06-ACTIVE-CHAIN-ON-FROZEN-C9-00

Marker: `U8_R0_LM06_ACTIVE_CHAIN_ON_FROZEN_C9_PASS`
Sim time: 190671945 ns. Wall ~58 s XSim.

DUT: `a7ng_gate14_c9_soa_lm_xsim` (legacy C9 graph + bind + TinyGPT SIM_FULL=1).
No TYPE_CLASS modules instantiated.

## Chain (required)

| Event | Count |
|---|---|
| ctx_we rise | 1 |
| ctx_we_beats | 1 |
| start_fwd pulses | 1 |
| start_fwd_beats | 1 |
| core_busy rise | 1 |
| core_done | 1 |
| C10 LMST rise | 1 |
| C10 LMDN rise | 1 |

H4 re-issue did **not** fire on this run (`sfwd_pulses=1`).

## Pred ownership

```text
c10_out   = 237
bind_pred = 237
core_pred = 237
exam_lm_used = 1
```

FPGA-owned. Host did not supply next-token.

## Host counters

```text
n_host_cue  = 0
n_host_win  = 0
n_host_addr = 0
n_host_tok  = 0
n_host_w    = 0
n_host_mode = 0
```

## HOLD_A (observed, not retargeted)

Historical immutable:

```text
HOLD_A C9 = 8382238122802120
OUT       = 653 / 689 / 237 / 60
```

This R0 exam fired token `0xA2` (HOLD_A) **without** the 20-fact A lesson.
Observed C9 pack `2322832182208180` (historical CONTRA pack) and OUT 237
(historical CONTRA OUT). `match HOLD_A = 0`.

That is **not** an oracle retarget. R0 does not grade HOLD_A pack/OUT.
Untrained legacy graph is not the 20-fact silicon exam.

## Not claimed

TYPE_CLASS→LM · encoder V1 · new oracle · Q-head · board · Gate14
