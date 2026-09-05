# PREREG — U4A-R6-ROUTE-VALIDITY-00

```text
GATE            = U4A-R6-ROUTE-VALIDITY-00
BASE            = 4d8694a
QUERY_LAW       = qse-v1-lexicon-hdc-00  KEY VALUES UNCHANGED
VALIDITY_LAW    = explicit bind-state bits, NOT (key != 0)
INDEX_VALIDITY  = valid=0 → do not insert that table
QUERY_VALIDITY  = valid=0 → do not probe that table
P4              = 4 tables, 4096 buckets, HEAD_CAP=64, CAND_CAP=64
TH_RECALL       = 0.80  (not retargeted)
RTL_EDIT        = YES (validity outputs + bind flags only)
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
PERSIST         = CLOSED until this PASS
U4_AXI          = CLOSED
U5              = CLOSED
GATE14_PASS     = NO
```

PRIMARY_UNKNOWN:
Can explicit semantic route validity keep absent features out of tables
while preserving key values, recall, and valid=1/key=0 probe?

k0_valid = (entity_id != 0) OR (intent_id != 0)
k1_valid = (relation_id != 0) OR (context_id != 0)
k2_valid = entity_class_bind occurred
k3_valid = intent_class_bind occurred

FORBIDDEN: valid = (key != 0); drop T3; key retarget; full-scan fallback.
