# CLOSEOUT — U7C-LEARN-STORE-LIMIT-00

```text
GATE                     = U7C-LEARN-STORE-LIMIT-00
RESULT                   = PASS
DECISION                 = LIMIT (not SCALE)
EVIDENCE_CLASS           = RTL_FACT + XSIM
RTL_EDIT                 = NO
DEPTH                    = 32
FIRST_NAK_AT_WRITE       = 33
STORE_OCCUPANCY_MAX      = 32
N_UNIQUE_LEARN_KEYS      = 32
PERSIST_RELOAD_MATCH     = 1
HOST_SEMANTIC_COUNTERS   = 0
U7_MARKER                = U7_CONTEXTUAL_LEARNING_EFFECTIVENESS_PASS
U7_SIM_TIME_NS           = 281015
LAW                      = LEARN_KEY_CLASS_CONTEXT_V1 UNCHANGED
800K_ONCHIP              = NOT_IN_THIS_CLOSE_PATH
BIT                      = NO
PROGRAM                  = NO
GATE14_PASS              = NO
QHEAD                    = NO
```

## Decision

Native V1 close uses the existing DEPTH=32 hot working set. Growing the
on-chip learned store to 800k is out of this DAG. G14-SCALE-800K-00
already recorded `C9_800K_STORE=NOT_IMPLEMENTED`. This gate converts
`LEARN_STORE_CAPACITY_32 OPEN HIGH_RISK` from a close-blocker into an
accepted LIMIT.

NAK at distinct write 33 is the law (U7A-R1: persist_nak, not persist_done
without BRAM write). Existing-key-while-full still commits.

## Evidence (this session)

U7 XSim re-run after QSE 30+30 + HEAPIFY load/compare:

- `STORE_OCCUPANCY_MAX=32`
- `FIRST_NAK_AT_WRITE=33`
- `NAK_COUNT=1`
- `PERSIST_RELOAD_MATCH=1`
- `HOST_SEMANTIC_COUNTERS=0`
- parameter `DEPTH = 32` in `rtl/native_graph/learn/a7ng_learned_prior_store.sv`

## Forbidden claims (not made)

800k hosted · silicon capacity · Q-head · production-scale learned memory ·
BOARD_PASS · Gate14.

## NEXT

`U7P-PERSISTENCE-IDENTITY-00` — FLUSH==RELOAD already 1 on this U7 run;
bag it. Then Root-B final. Not U8R. Not PROGRAM.
