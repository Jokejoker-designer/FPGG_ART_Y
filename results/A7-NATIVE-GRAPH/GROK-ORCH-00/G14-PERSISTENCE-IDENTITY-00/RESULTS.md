# RESULTS — G14-PERSISTENCE-IDENTITY-00

```text
ROOT/GATE                    = G14-PERSISTENCE-IDENTITY-00
CLASS                        = QUERY_VISIBLE_IDENTITY_XSIM_PASS
FIRST_DIVERGENCE             = NONE on C9 / lookup (16-bit Gate14 keys)
ROOT_CAUSE                   = n/a (identity holds for query-visible state)
FIX                          = none
XSIM                         = PASS store + HOLD_A C9
IMPLEMENTATION               = no
BOARD_REQUIRED               = no (not this bit)

ROOT_A_EPOCH                 = BOARD_CLOSED (1F0F2ABB historical; do not reprogram)
ROOT_B_TRANSACTION           = PARTIALLY_CONFIRMED (archived)
PERSISTENCE_IDENTITY         = XSIM_CLOSED for query-visible; C8 sdig observe-only NOT restored
RESET_RETRAIN                = OPEN_ACCEPTANCE
TEACHER_OFF                  = OPEN
LM_ACTIVE_CHAIN              = OPEN
SCALE_800K                   = OPEN

READY_TO_PROGRAM             = NO
PROGRAM                      = NO
GATE14_PASS                  = NO
BOARD_PASS                   = not_claimed
NATIVE_V1_MINI_AI_BOARD_PASS = NO
```

Evidence class: **XSIM**. Not BOARD.

## Contract

```text
state before FLUSH  ==  state after KILL + RELOAD
```

Tracked: generation, occupancy (via lookup hit), {s,r,o} 16-bit, pri, pen, HOLD_A C9.

## Store TB (`XSIM`)

```text
PRE_FLUSH  GEN=1 seq=8 ack=8 lookup 8/8 pri=3
KILL       lookup miss
RELOAD     GEN=1 lookup 8/8 pri=3
TRUNC32    full-key hit=0  truncated-key hit=1   (16-bit DDR key LATENT)
C8_SDIG    pre=0000000000030107  post=0   kill zeros; RELOAD does not rebuild
```

Marker: `PERSIST_IDENTITY_STORE_XSIM_PASS`

## Graph C9 TB (`XSIM`)

```text
PRE_FLUSH   HOLD_A C9=8382238122802120 GEN=2 seq=20 ack=20
AFTER_KILL  HOLD_A C9=2322832182208180  (C3; vis hidden)
AFTER_RELOAD HOLD_A C9=8382238122802120 GEN=2
```

Marker: `PERSIST_IDENTITY_C9_XSIM_PASS`

KILL hiding vis is required. Matching C9 after reload is the identity.

## Classification

| Item | Class |
|------|-------|
| Query-visible C9 / lookup identity | XSIM PASS |
| C8 sdig not rebuilt on RELOAD | LATENT_DEFECT observe-only (not C9) |
| 16-bit DDR key truncation | LATENT_DEFECT (Gate14 keys fit) |
| BOARD persistence identity | still OPEN_ACCEPTANCE (do not reuse 1F0F2ABB) |

Do not patch sdig/truncation into a new bit mixed with reset/retrain.
