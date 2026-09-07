# PREREG — U1-HARNESS-AUTHORITY-FIX-00

```text
GATE        = U1-HARNESS-AUTHORITY-FIX-00
BASE        = U0 freeze commit on grok-orch/v31-canonical-00
RTL_EDIT    = YES  test harness / TB only (production RTL freeze unless a
                   TB bind defect is proven to be DUT)
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO

PRIMARY_UNKNOWN =
  Can the MIG metric harness fail closed so SOA_PATTERN_FAIL implies
  FAIL, cell_fail=0 is required, and N=64 AOS 1024 B / 64 beats is the
  exact control — without changing C9/OUT/TopK/PHYS/WAVE?

CANONICAL_LAW =
  any SOA_PATTERN_FAIL => FAIL
  cell_fail must equal 0
  N=64 AOS = 1024 bytes / 64 beats
  merge_done = wave completion authority
  ordered_valid = final ordered result authority
  final ordered_valid may arrive after running=0
  intentional corruption must FAIL

KEEP = PHYS=4 WAVE=16 burst=16 TopK Fold6 scorer C9 LM oracle
NOT_THIS_GATE = synth, bit, program, sparse router, ping-pong re-edit
```
