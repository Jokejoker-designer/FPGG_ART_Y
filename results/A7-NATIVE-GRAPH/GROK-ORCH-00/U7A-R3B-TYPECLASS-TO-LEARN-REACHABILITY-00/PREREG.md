# PREREG — U7A-R3B-TYPECLASS-TO-LEARN-REACHABILITY-00

```text
GATE   = U7A-R3B-TYPECLASS-TO-LEARN-REACHABILITY-00
BASE   = ed9c9a8c747550d81fdae119c62e3c03b6815ff1
LAW    = LEARN_KEY_CLASS_CONTEXT_V1 (OWNER_LOCK)
UNKNOWN= Can TYPE_CLASS Top-K CLASS_ID reach G1→G2→store→lookup→scorer
         with FPGA-built LEARN_KEY_CLASS_CONTEXT_V1?
RTL    = YES (new key law + R3B wrapper only)
U6     = UNCHANGED (learn=0 retrieval)
U7     = CLOSED
QHEAD  = NO
BIT    = NO
PROGRAM= NO
C7_ADDR= OBSERVE_ONLY
HOST_TARGET = FORBIDDEN
RAW_NID     = FORBIDDEN in learn key
```

PASS requires XSim:

1. CLASS_ID 58 + "chiller" vs "water chiller" → distinct store keys, both HIT
2. Same CLASS_ID + same QSE twice → same key, prior accumulates
3. High CLASS_ID >255 survives in subj[15:0]
4. Bind-mask falsifier (rel=0, same numeric obj) MISSes
5. Scorer receives learned_prior
6. n_host_or = 0; no NID in key; prefix 16'h5443
