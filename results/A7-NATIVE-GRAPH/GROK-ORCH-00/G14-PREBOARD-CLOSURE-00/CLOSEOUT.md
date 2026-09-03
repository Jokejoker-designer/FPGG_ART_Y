# CLOSEOUT — G14-PREBOARD-CLOSURE-00

```text
PROGRAM = NO
GATE14_PASS = NO
READY_TO_PROGRAM = NO
```

Diagnosis: Gate14 persist forked RESET-00's epoch law into a DRAM cookie
restore. vis_w on an 8-bit slice then treated garbage as learned prior.
P0 `header_ok` closed one entry. P_INVAL was still not REBIRTH.

Fix: one epoch type in `a7ng_pkg` (`ng_epoch_legal/pack/gen/visible`);
P_INVAL → P_CLR with `live_gen=1`; both persist FSMs share the cookie law.

XSim PASS for epoch matrix, dirty-boot regression, C9-03 oracle pack.
Silicon unique bit not built. Human still owns PROGRAM.
