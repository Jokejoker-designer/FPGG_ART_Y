# GitHub PR — DDR-EXPOSED-REMEASURE-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y
Existing PR (do not merge as Gate14 pass):
https://github.com/Jokejoker-designer/FPGG_ART_Y/pull/11

```text
GATE14_PASS = NO
PROGRAM     = NO
BIT_BUILD   = NO
M10         = KEEP_OPEN
ORACLE      = HOLD
RTL_EDIT    = NO
```

Measurement only. No production RTL.

C_D_SERVICE is recurring 44/42/42/42 and **is** II_STEADY=46.
C_D_EXPOSED occupancy is startup-only (45 / 9 / 0 / 0).
LAST_R→NEXT_AR is 6–7 cycles (not a launch hole).
FINAL_G_TAIL=122 is last-wave Global after last accept, not DDR.

NEXT = `DDR-WAVE-PINGPONG-00`.
Not `GLOBAL-TAKE-SIFT-00`. Not `DDR-LAUNCH-DECOUPLE-00`.

Do **not** merge as Gate14 pass. Do not program.
