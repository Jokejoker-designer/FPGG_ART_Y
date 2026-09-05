# CLOSEOUT — U7A-R1-STORE-FULL-COMMIT-LAW-00

```text
GATE                     = U7A-R1-STORE-FULL-COMMIT-LAW-00
BAG                      = U7A-R1-STORE-FULL-PERSIST-DONE-LAW-00
BASE                     = b93520f39541455e26f08d64960f660ba6a1e701
RTL_EDIT                 = YES  rtl/native_graph/learn/a7ng_learned_prior_store.sv
U7A                      = FAIL immutable
RESULT                   = PASS
EVIDENCE_CLASS           = XSIM
FIRST_DIVERGENCE         = none this gate

LAW                      = ordinary BRAM commit ⇔ wrote||ram_we
                           persist_done/c7_ack/ack_count only then
                           else persist_nak (fail completion, not success)
                           G1 ACK_CONSUME unchanged (txn consumed ≠ store commit)

CLAIM_ALLOWED            = Store-full no longer reports persist_done/ack_count
                           without BRAM write. Existing-key-while-full still
                           commits once. XSim.
CLAIM_NOT_ALLOWED        = U7A un-fail, U7, TYPE_CLASS→learn, persist_gen_fast
                           fixed, silicon, board, Gate14, U6 timing PASS

BIT                      = NO
PROGRAM                  = NO
REPROGRAM_AGAIN          = NO
U7                       = CLOSED
TYPE_CLASS_TO_LEARNING   = NOT_REACHABLE
U6_TYPECLASS_MINHEAP_TIMING = OPEN (OOC WNS -4.103 ns)
C7_ADDR                  = OBSERVE_ONLY
NEXT                     = U7A-R2-ROOT-B-CLOSURE-00
                           Do not open U7.
```
