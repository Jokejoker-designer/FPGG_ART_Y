# PREREG — U4A-R5-NULL-KEY-TABLE-ABLATION-00

```text
GATE            = U4A-R5-NULL-KEY-TABLE-ABLATION-00
BASE            = 917f3488e5972cad1fbe92a7510e2541337c6501
QUERY_LAW       = qse-v1-lexicon-hdc-00  UNCHANGED
PROFILE         = P4_4k_h64  NOT FROZEN
CAND_CAP        = 64         NOT FINAL
RTL_EDIT        = NO
DO_NOT          = key==0 → skip
PERSIST         = CLOSED
U4 AXI          = CLOSED
U5              = CLOSED
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
GATE14_PASS     = NO
EVIDENCE        = HOST_MODEL
```

PRIMARY_UNKNOWN:
Which P4 table/key causes admit-all, and is key=0 a legitimate route
value or an absent/unknown feature incorrectly routed into bucket 0?

From frozen qse packet law (do not retarget):
  entity_id/intent_id/relation_id/context_id : 0 = unknown
  k0 = {entity_id, intent_id}   → k0==0 means both IDs unknown
  k1 = {relation_id, context_id} → k1==0 means both IDs unknown
  k2 = entity_cue[15:0]  initial 0; bind only on entity-class hit
  k3 = intent_cue[15:0]  initial 0; bind only on intent-class hit

Ablations (same index construction as U4A-R3/R4; union only listed tables):
  T0 T1 T2 T3 T01 T02 T03 T12 T13 T23 ALL4

Queries: same six directed queries as U4A-R4.

This gate MEASURES. It does not repair routing. U4A-R6 only if R5 shows
0 = absent/unknown on the ID keys.
