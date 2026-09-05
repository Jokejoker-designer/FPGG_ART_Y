# CLOSEOUT — U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00

```text
GATE                     = U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00
BASE                     = e133c2805b59c7cb631e99be82f6c5ca7bb528dd
R3B_RTL                  = 2f7155240134fa0a49cf628b86cadc69c51593cb
OWNER_LOCK               = LEARN_KEY_CLASS_CONTEXT_V1
RTL_EDIT                 = YES (ranking wrapper only)
U6_RETRIEVAL             = UNCHANGED (learn=0 control)
RESULT                   = PASS
SCOPE                    = XSim working set (store DEPTH=32)
EVIDENCE_CLASS           = XSIM
FIRST_DIVERGENCE         = none
SIM_TIME                 = 276335 ns
MARKER                   = U7_CONTEXTUAL_LEARNING_EFFECTIVENESS_PASS

LEARNED_STATE_IDENTITY   = TYPE_CLASS × QUERY_CONTEXT
LAW                      = LEARN_KEY_CLASS_CONTEXT_V1
CHAIN                    = query → QSE poke → scan → mat → V1 lookup
                           → learned_prior → scorer → Top-K heap
LOOKUP_BEFORE_HEAP       = YES
QHEAD                    = NO
BIT                      = NO
PROGRAM                  = NO
REPROGRAM_AGAIN          = NO
C7_ADDR                  = OBSERVE_ONLY
U6_TYPECLASS_MINHEAP_TIMING = OPEN (OOC WNS = -4.103 ns)
LEARN_STORE_CAPACITY_32  = OPEN HIGH_RISK_ARCHITECTURAL_HAZARD
```

## Allowed claim

Under the frozen LEARN_KEY_CLASS_CONTEXT_V1 identity,
FPGA-owned scalar-reward updates causally and context-specifically
modify learned prior values and subsequent TYPE_CLASS ranking in XSim,
with the tested learned state surviving the audited persistence path.

## Forbidden claims (not made)

generalization · reasoning · Q-learning · Q-head · NLU · LM generation ·
silicon learning · board learning PASS · Gate14 · production-scale
learned-memory capacity · persist_gen_fast repaired
