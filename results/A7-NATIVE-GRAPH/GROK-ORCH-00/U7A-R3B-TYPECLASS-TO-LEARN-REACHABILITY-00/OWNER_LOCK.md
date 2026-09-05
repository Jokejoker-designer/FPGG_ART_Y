# OWNER_LOCK_TOKEN — U7A-R3 LEARNED STATE IDENTITY

```text
OWNER_DECISION = LOCK

LEARNED_STATE_IDENTITY = TYPE_CLASS × QUERY_CONTEXT
LAW                    = LEARN_KEY_CLASS_CONTEXT_V1
```

subj[31:0] = {16'h5443, CLASS_ID[15:0]}
rel[7:0]   = {4'b0000, q_x_valid, q_r_valid, q_i_valid, q_e_valid}
obj[31:0]  = {q_eid[7:0], q_iid[7:0], q_rid[7:0], q_xid[7:0]}

- Same CLASS_ID under different query context MAY have different learned state.
- Same CLASS_ID + identical QSE fields + identical bind mask MUST map to the same key.
- RAW_NID is provenance only and MUST NOT participate.
- Host MUST NOT select or construct the learning target.
- CLASS_ID MUST NOT be treated as NID.
- C7_ADDR remains OBSERVE_ONLY.
- Full32 SchemaV2 remains persistence authority.
- Reserve subj[31:16] = 16'h5443. Do not reuse without a new versioned owner decision.

U7A original = FAIL immutable
U7A-R1 = PASS
U7A-R2 = PASS
U7A-R3A = MEASURE_PASS_DECISION_REQUIRED, resolved by this lock
U7 = CLOSED
QHEAD = NO
BIT = NO
PROGRAM = NO
