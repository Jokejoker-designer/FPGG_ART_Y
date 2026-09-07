# ACCEPTANCE — U5Q-M10-TYPECLASS-SCALE-00

```text
AUDITOR   = gstack-acceptance-auditor analog (report-only)
VERDICT   = PASS
OVERCLAIM = false
FRAUD     = false
```

Hunt notes:

- Retrieval law is complete class-table conjunctive, so rec/prec=1.0 is
  expected when |gold types|≤64. Not NID-router cheating. Gold is not
  `router_union`.
- Truncation would FAIL via `GOLD_EXCEEDS_CAND_CAP`; max gold=47.
- Legacy NID CONTROL still fails recall — not hidden.
- Evidence class HOST_MODEL, not FPGA XSim at each N, not BOARD.
- Does not close U6 OOC WNS −4.103, learn-store DEPTH=32, or silicon.

Do not auto-open U8R / U9 / PROGRAM.
