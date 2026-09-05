# GitHub PR — GLOBAL-MERGE-DONE-SPLIT-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y

```text
GATE14_PASS = NO
PROGRAM     = NO
BIT_BUILD   = NO
M10         = KEEP_OPEN
ORACLE      = HOLD
```

Do **not** merge as Gate14 pass. Contract split only.

`merge_done_o` is an independent completion token. This gate still sorts
every wave (28×4) and still pulses `global_valid_o` every wave.
T_QUERY=397 C_G_MAX=52 unchanged. C9/OUT frozen.

NEXT = `GLOBAL-SORT-FINAL-ONLY-00`.
