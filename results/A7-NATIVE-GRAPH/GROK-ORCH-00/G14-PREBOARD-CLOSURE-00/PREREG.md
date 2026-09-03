# PREREG — G14-PREBOARD-CLOSURE-00 epoch identity

```text
PROGRAM = NO
GATE14_PASS = NO
```

BASE_SHA = `1e71eb12b12be4405fa7aa490b2da04782ad18eb`
branch   = `grok-orch/g14-preboard-closure-00`

Hypothesis (falsifiable):

```text
H1  Illegal DDR cookies never become live_gen (I6).
H2  TRESET below WRAP_LIMIT is BUMP: old vis_w rows disappear, new writes commit.
H3  TRESET at WRAP_LIMIT is REBIRTH: live_gen=1, BRAM vis_w empty, DDR[0] illegal.
H4  persist_gen_fast uses the same ng_epoch_legal as the active store (I7).
```

If H3 fails, P_INVAL is still a DDR-only scrub and Gate14 forget is not closed.

Does not authorize board programming.
