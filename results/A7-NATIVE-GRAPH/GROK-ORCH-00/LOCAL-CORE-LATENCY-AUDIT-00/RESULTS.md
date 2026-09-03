# RESULTS — LOCAL-CORE-LATENCY-AUDIT-00

Measurement only. No production RTL. MIG_XSIM after CUE-OVERLAP.

```text
LOCAL_CORE_AUDIT_DONE waves=4 C_L_MAX=96 ISSUE_TO_IDLE_MAX=104
LOCAL_CORE_OCC FIRE=16 WAIT=32 STREAM=132 COLLECT=151 COMMIT=4 PUSH=32
LOCAL_CORE_PUSH_AFTER_TOPK=32
LOCAL_CORE_DOMINANT=HEAP_COLLECT
```

Per wave (C_L = fire→commit; PUSH is after TopK, on issue→idle):

| wave | C_L | FIRE | WAIT | STREAM | COLLECT | COMMIT | PUSH |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 96 | 4 | 8 | 42 | 40 | 1 | 8 |
| 1 | 81 | 4 | 8 | 30 | 37 | 1 | 8 |
| 2 | 81 | 4 | 8 | 30 | 37 | 1 | 8 |
| 3 | 81 | 4 | 8 | 30 | 37 | 1 | 8 |

Scorer WAIT is 8 cycles/wave (not the limiter). Heap STREAM+COLLECT is 67–82 of C_L=81–96.

ST_PUSH is 8 cycles after `topk_valid` (`frontier_pop_i` tied 1 in this instance). It is on issue→idle (104) but not on C_L. Not the C_L bottleneck.

Authority next:

```text
SCORER-HEAP-DECOUPLE-00   ← heap STREAM/COLLECT serialization
not FRONTIER-DEADPATH-00  ← PUSH only +8, parent does pop in this TB
not parallel heaps        ← not yet; first a score/stream FIFO
```
