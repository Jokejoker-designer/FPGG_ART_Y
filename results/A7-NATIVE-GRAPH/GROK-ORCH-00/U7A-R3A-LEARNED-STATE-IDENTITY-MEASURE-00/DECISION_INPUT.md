# DECISION_INPUT — owner lock, not agent lock

```text
GATE   = U7A-R3A-LEARNED-STATE-IDENTITY-MEASURE-00
RESULT = MEASURE_PASS_DECISION_REQUIRED
RTL    = NO
U7     = CLOSED
```

## Question for owner

After TYPE_CLASS retrieval, what is `LEARNED_STATE_IDENTITY`?

## Evidence-supported candidate (not selected)

```text
LEARNED_STATE_IDENTITY = TYPE_CLASS × QUERY_CONTEXT
LAW                    = LEARN_KEY_CLASS_CONTEXT_V1
```

subj = `{16'h5443, CLASS_ID}`
rel[3:0] = `{q_xv, q_rv, q_iv, q_ev}`
obj = `{q_eid, q_iid, q_rid, q_xid}`

Measured:

1. injective on tested (CLASS_ID, query-context) pairs including all 443 classes
2. no collision with sampled legacy graph namespace
3. no raw-NID dependency
4. no host-selected target
5. deterministic FPGA construction from U6 CLASS_ID + QSE
6. compatible with full32 SchemaV2 triple
7. high CLASS_ID (>255, 427) survives
8. "chiller" vs "water chiller" on CLASS_ID 58 **distinguishable**

CLASS_ONLY **fails** item 8 (aliases 58).

RAW_MEMBER requires a member-selection law not present; U6 stream has CLASS_ID not NID.

LEGACY `{subj,rel,obj}` is **NOT_REACHABLE** from U6 Top-K.

## Working-set note (for later U7, not this decision)

Gold unique CLASS_CONTEXT keys = 113 > store 32.
R1 NAK-on-full still applies. Do not treat this as NO_VALID_MAPPING.

## If owner locks CLASS_CONTEXT_V1

Open next (dedicated):

```text
U7A-R3B-TYPECLASS-TO-LEARN-REACHABILITY-00
```

Chain (not built in R3A):

```text
Top-K CLASS_ID
→ FPGA LEARN_KEY_CLASS_CONTEXT_V1
→ G1 pending txn
→ scalar reward
→ G2 delta
→ learned_prior_store
→ lookup prior
→ scorer
```

Still: U7 CLOSED until that reachability gate PASSes. QHEAD=NO BIT=NO PROGRAM=NO.

## Agent must not

- lock the identity
- edit RTL
- open R3B without explicit owner approval
- set LEARNED_STATE_IDENTITY = CLASS_ID
