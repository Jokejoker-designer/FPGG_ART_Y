# PREREG — G14-RESET-RETRAIN-00

```text
PROGRAM          = NO
GATE14_PASS      = NO
RTL_EDIT         = NO
WORKTREE         = grok-orch-00
UNKNOWN          = After TRAIN_A, does FORGET/RESET hide A query-visible state, and does RETRAIN_B create B without resurrecting A?
ROOT CAUSE       = not claimed
FALSIFIER        = HOLD_A still oracle after TRESET; HOLD_B not oracle after B; HOLD_A returns A after B
EXPECTED         = BASELINE → A_VISIBLE → A_NOT_VISIBLE → B_VISIBLE → A_NOT_RESURRECTED
REGRESSION       = frozen oracle HOLD_A C9=8382238122802120 OUT=653; HOLD_B C9=8382438142804140 OUT=60
```

Frozen: bit `1F0F2ABB`, Root A BOARD_CLOSED, persistence identity `3a06bd3`,
scorer/Top-K/TinyGPT/bind, no sdig/key/WDMA/AXI edits.
