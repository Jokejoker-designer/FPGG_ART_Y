# CLOSEOUT — U7A-ROOT-B-REACHABILITY-REAUDIT-00

```text
GATE                     = U7A-ROOT-B-REACHABILITY-REAUDIT-00
BASE                     = 930c70747e342d9da57a4d553d89bb3e12c48333
U6_RTL                   = 9c39a4a3caa1de5723c7bd0699b386a45863604f
RTL_EDIT                 = NO
FILES_CHANGED            = results/.../U7A-ROOT-B-REACHABILITY-REAUDIT-00/*
                           NativeAI_CLI_V01 status bump

MASTER_RETRIEVAL_OBJECT  = TYPE_CLASS
TOPK_ID_SEMANTICS        = CLASS_ID
LEARNED_STATE_IDENTITY   = {subj,rel,obj} in store — NOT CLASS_ID (not assumed)

PRIMARY_UNKNOWN          = SUCCESS ⇔ INTENDED_STATE_TRANSITION_COMMITTED
                           with TYPE_CLASS as retrieval identity?
RESULT                   = FAIL
CLASS                    = CONFIRMED_DEFECT
EVIDENCE_CLASS           = RTL_FACT + XSIM
FIRST_DIVERGENCE         = persist_done/ack_count without BRAM commit
                           (store full, wrote=0, 33rd distinct key)
VIOLATED_INVARIANT       = SUCCESS ⇔ INTENDED_STATE_TRANSITION_COMMITTED

SYMPTOM                  = 33rd distinct update: persist_done=1, ack_count=33,
                           commit_seq=32, lookup miss
ARCHITECTURAL_OWNER      = a7ng_learned_prior_store P_UPD tail
DUPLICATE_IMPLEMENTATIONS = persist_done also a7ng_persist_gen_fast
DOWNSTREAM_EFFECTS       = persist_done/ack cannot be treated as commit;
                           U7 baseline learning blocked
SMALLEST_NEXT_EXPERIMENT = persist_done/c7_ack only if wrote==1 (or explicit NAK).
                           Do not add TYPE_CLASS→learn wiring in the same patch.

TYPE_CLASS_REACHABILITY  = NOT_REACHABLE
C7_ADDR                  = OBSERVE_ONLY (not proof)
U6_TYPECLASS_MINHEAP_TIMING = OPEN (OOC WNS -4.103 ns) — not closed here

CLAIM_ALLOWED            = TYPE_CLASS path cannot reach current learn/persist.
                           Current store raises persist_done/ack_count on
                           store-full with no BRAM commit (XSim).
CLAIM_NOT_ALLOWED        = U7 PASS, Q-head, silicon TYPE_CLASS, board, Gate14,
                           SoC Root-B closed, U6 timing PASS

BIT_BUILD                = NO
PROGRAM                  = NO
REPROGRAM_AGAIN          = NO
GATE14_PASS              = NO
U7                       = CLOSED
U8                       = CLOSED
NEXT                     = store-full persist_done law (one unknown).
                           Not U7. Not TYPE_CLASS integration until that law holds.
```

Supersedes the earlier paper-only U7A bag on this path. This closeout is the
XSim-backed verdict.
