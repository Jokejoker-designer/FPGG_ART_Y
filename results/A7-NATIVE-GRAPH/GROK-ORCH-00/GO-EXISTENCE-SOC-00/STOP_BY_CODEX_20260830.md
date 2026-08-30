# STOP — competing Grok physical build — 2026-08-30T08:36+07

Codex coordination lead stopped the two `wait_then_impl.ps1` waiter processes before they launched a second Vivado implementation.

Reason: Cursor owns the sole product/P&R lane in `arty-a7-online-lm-close664`. Grok is assigned read-only gate `GROK-CLOSE664-INDEPENDENT-AUDIT-00`.

```text
PROGRAM=NO
P&R=STOPPED_BEFORE_START
PRODUCT_RTL=preserved
GROK_ARTIFACTS=preserved
```

## Human clarification override — 2026-08-30

The human clarified that Grok is an independent research branch. This stop no longer forbids the research build. The waiter may be relaunched, but must continue to wait until Cursor PID 175800 and every foreign Vivado process finish. PROGRAM remains NO.
