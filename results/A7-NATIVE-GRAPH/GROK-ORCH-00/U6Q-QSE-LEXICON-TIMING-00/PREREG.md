# PREREG — U6Q-QSE-LEXICON-TIMING-00

```text
GATE              = U6Q-QSE-LEXICON-TIMING-00
LAW               = qse-v1-lexicon-hdc-00 UNCHANGED
PRIMARY_UNKNOWN   = post-route OOC WNS of U6 top after 2-stage lexicon match
SPLIT             = 30 + 30 (QSE_N_LEX=60)
RTL_EDIT          = YES (QSE control only)
BIT               = NO
PROGRAM           = NO
```

Match/apply still first-hit then min-id within class. Extra 2 cycles per
word flush. Fire with empty wbuf still publishes accumulated ids.
