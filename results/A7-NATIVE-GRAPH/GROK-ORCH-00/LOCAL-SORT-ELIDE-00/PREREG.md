# PREREG — LOCAL-SORT-ELIDE-00

```text
GATE        = LOCAL-SORT-ELIDE-00
BASE        = LOCAL-WAVE-ORDER-CONTRACT-AUDIT PASS
RTL_EDIT    = YES
  a7ng_topk_stream_minheap.sv  parameter SORT_BEFORE_DRAIN (default 1)
  a7ng_ng02_core.sv            SORT_BEFORE_DRAIN=0
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Can NG02 skip local ST_SORT and drain the K-set in heap-array
              order so COLLECT drops ~28 cycles without changing global
              (score,id) or C9/OUT?

NOT_THIS_GATE =
  beats()
  heap TAKE/HEAPIFY
  global ST_SORT
  PHYS
  score skid / bidx split
  C9 instance (keeps default SORT_BEFORE_DRAIN=1)

H_CANDIDATE = local SET DIFF=0 vs ordered drain; C_L falls; C9/OUT freeze
FALSIFIER   = SET mismatch; C9/OUT change; deadlock; C_L not down
```
