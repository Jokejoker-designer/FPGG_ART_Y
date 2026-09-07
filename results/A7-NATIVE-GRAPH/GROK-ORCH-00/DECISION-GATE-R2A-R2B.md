# DECISION GATE — after R2A + R2B

Owner decision. Agents do not choose Master object here.

```text
U4 PASS / U5 PASS / U6 XSim RETAINED
U5Q FAIL / U5Q-R1 FAIL
U6B PHYSICAL_SUBSTRATE PASS  (1F0F2ABB; REPROGRAM_AGAIN=NO)
U5Q-R2A MEASURE_PASS  RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP
U5Q-R2B MEASURE_PASS  PARTIAL_FIELD_COLLISION  (not full vis inseparable)
U7A CLOSED  U7 CLOSED  U8 CLOSED  GATE14 NO
```

Facts:

1. At N=800k, chiller gold = 34000 raw nids / 29 TYPE_CLASS / 323 texts.
   Raw recall 0.80 needs ≥27200 cands. Class recall 0.80 needs ≥24. Cap=64.
2. Full router vis `{k0..k3,valid}` has **no** relevant=irrelevant twins.
3. UNION still pulls FPs via shared k1/k3 (water: all four keys).

Repair axes (owner):

- retrieval **object** (instance vs TYPE_CLASS), and/or
- query/record **features** / probe law (UNION vs which tables),
- not another head/bucket/cap sweep on the same vis.

Owner decision recorded in `OWNER_DECISION-TYPE-CLASS-00.md`:

```text
MASTER_RETRIEVAL_OBJECT = TYPE_CLASS
RAW_EPISODE_ID          = provenance only
TYPE_TEXT               = NOT_SELECTED
NEXT_RETRIEVAL_LAW      = masked conjunctive
```

U5Q-T1 host-model TYPE_TABLE = PASS. Legacy nid-collapse class recall still
fails (chiller 0.17 @800k). No U7A. No NID cap sweep. No QSE redesign yet.
