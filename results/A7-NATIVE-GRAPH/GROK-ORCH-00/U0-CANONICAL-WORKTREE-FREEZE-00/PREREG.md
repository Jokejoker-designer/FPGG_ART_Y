# PREREG — U0-CANONICAL-WORKTREE-FREEZE-00

```text
GATE        = U0-CANONICAL-WORKTREE-FREEZE-00
AUTHORITY   = UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md
RTL_EDIT    = NO
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = OPEN
HS13        = OPEN
COM12       = UNTOUCHED

PRIMARY_UNKNOWN =
  Is the product lineage exact, traceable, and free of generated MIG
  churn so V3.1 DAG can start without cross-worktree contamination?

MUST =
  record OBSERVED_HEAD vs BLUEPRINT_SNAPSHOT_HEAD
  SHA production RTL from git HEAD (not dirty tree)
  quarantine generated MIG dirt (do not commit)
  archive frozen board bit hashes
  name clean integration branch
  no cross-write to other worktrees
  prereg U1

NOT_THIS_GATE = RTL patch, synth, bit, program, U1 harness edit
```
