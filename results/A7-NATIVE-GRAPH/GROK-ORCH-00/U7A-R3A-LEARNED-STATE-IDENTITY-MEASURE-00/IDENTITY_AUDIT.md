# IDENTITY_AUDIT — U7A-R3A-LEARNED-STATE-IDENTITY-MEASURE-00

```text
GATE   = U7A-R3A-LEARNED-STATE-IDENTITY-MEASURE-00
BASE   = 2d3f3e4c60e39637c5e616de5572c8ffa22296f6
RTL_EDIT = NO
RESULT = MEASURE_PASS_DECISION_REQUIRED
```

PRIMARY_UNKNOWN: what identity should a reward update target after TYPE_CLASS
is the production retrieval object?

Do **not** assume `LEARNED_STATE_IDENTITY = CLASS_ID`.
Do **not** use raw NID merely because it exists.
This gate does **not** decide. Owner lock required.

## Current interface

U6 materializer: `CLASS_ID, eid, iid, rid, xid, member_ptr, member_count`.

`member_ptr` = catalog index of first TYPE_CLASS member, **not** 800k episode NID.

Baseline store key: `{subj[31:0], rel[7:0], obj[31:0]}`.
No lossless CLASS_ID→triple exists without an explicit construction.

## LEARN_KEY_CLASS_CONTEXT_V1 (evaluated, not promoted)

```text
subj = {16'h5443, CLASS_ID}     // 'TC' || CLASS_ID
rel[3:0] = {q_xv, q_rv, q_iv, q_ev}
rel[7:4] = 0
obj = {q_eid, q_iid, q_rid, q_xid}
```

FPGA-only. QSE fields already owned. No host-selected target.

## Critical: CLASS_ID 58

| Query | CLASS_ONLY key | CLASS_CONTEXT_V1 (subj,rel,obj) |
|-------|----------------|----------------------------------|
| chiller | 58 | (0x5443003A, 0x1, 0x01000000) |
| water chiller | 58 | (0x5443003A, 0x9, 0x01000001) |

CLASS_ONLY **aliases**. CLASS_CONTEXT **does not**.

## Rival summary

| Rival | Gold collisions (distinct QSE tuples) | Same-class/diff-query alias | Member pick | SchemaV2 | Lookup before score | Host target |
|-------|----------------------------------------|-----------------------------|-------------|----------|---------------------|-------------|
| A CLASS_ONLY | **yes** (e.g. 58, 65–71, …) | **yes** | no | would need new width | if keyed by CLASS_ID | no |
| B CLASS_CONTEXT_V1 | **none** | **no** | no | fits triple | CLASS_ID + latched QSE | no |
| C RAW_MEMBER | n/a without pick law | yes if first-member | **yes** | packing TBD | NID not in U6 stream | unless FPGA law frozen |
| D LEGACY triple | n/a | n/a | no | yes | yes on graph ROM | no; **U6 NOT_REACHABLE** |

V1 injective on 443 × (gold unique tuples + synth unbound-mask).
V1 subj prefix `0x5443` does not hit sampled legacy `0xA000+i` / `0x00011234` / pad `0x00FFFFF0`.
CLASS_ID 427 and gold IDs >255 survive in subj[15:0].
Same numeric q-fields with different bind mask differ in `rel[3:0]`.

## Cardinality (not a mapping veto)

Store DEPTH=32. Unique CLASS_CONTEXT keys on collapsed gold = **113** (does not all fit).
443 classes cannot all sit in WS. Eviction/NAK law already exists. This is resource, not identity failure.

## Result

```text
RESULT = MEASURE_PASS_DECISION_REQUIRED
```

CLASS_CONTEXT_V1 is **evidence-supported** against the listed requirements.
Not owner-locked. Not wired. U7 CLOSED.
