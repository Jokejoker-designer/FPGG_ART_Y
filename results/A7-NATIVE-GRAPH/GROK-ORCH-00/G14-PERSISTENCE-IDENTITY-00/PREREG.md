# PREREG — G14-PERSISTENCE-IDENTITY-00

```text
PROGRAM          = NO
GATE14_PASS      = NO
RTL_EDIT         = NO
WORKTREE         = grok-orch-00
UNKNOWN          = After legal epoch, does BRAM state before FLUSH equal query-visible state after KILL+RELOAD?
ROOT CAUSE       = not claimed
FALSIFIER        = slot {occ,gen-stamp,s,r,o,pri,pen} and HOLD_A C9 mismatch across FLUSH/KILL/RELOAD
EXPECTED         = identity of persisted payload (16-bit keys) and C9
REGRESSION       = frozen oracle HOLD_A C9=8382238122802120; do not retarget
```

Do **not** program `1F0F2ABB`. That bit is a historical BOARD artifact.

Board may be attached (COM12). This gate is XSim-only until a new unique bit is preregistered.
