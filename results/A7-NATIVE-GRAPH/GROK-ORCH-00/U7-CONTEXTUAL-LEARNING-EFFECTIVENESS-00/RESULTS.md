# RESULTS — U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00

Evidence: `xsim.log` marker `U7_CONTEXTUAL_LEARNING_EFFECTIVENESS_PASS`.
Host/TB provided only txn echo + preregistered ordinal scalar reward.

## E1 baseline (install chiller, freeze=1, no train)

| rank | CLASS_ID | score |
|------|----------|-------|
| 0 | 65 | 16 |
| 1 | 66 | 16 |
| 2 | 67 | 16 |

Heap tie law `valid > score > id<`. Priors 0.

## E2 freeze control

Identical stimulus, `train_after=1`, `freeze=1`.
`c7seq` unchanged (0). `n_learned=0`. Ranking unchanged.

## E3 causal rank flip — SCHED_A = [-1, +2, 0]

Training query ranked 65,66,67 (priors still 0), then G1 walk of valid Top-K.
After freeze re-query:

| CLASS_ID | PRIOR_BEFORE | REWARD | PRIOR_AFTER | FINAL_SCORE | RANK_BEFORE | RANK_AFTER |
|----------|--------------|--------|-------------|-------------|-------------|------------|
| 65 | 0 | -1 | -1 | 15 | 0 | 2 |
| 66 | 0 | +2 | +2 | 18 | 1 | 0 |
| 67 | 0 |  0 |  0 | 16 | 2 | 1 |

Top-K after: **66@18, 67@16, 65@15**.

F1 LEARNING_NOT_CAUSAL_TO_RANKING = not triggered.
Negative demotion (reward −1 on CLASS_ID 65) = supported by G1 {−3..+3}.

Duplicate last txn after A: `ack=6` (ACK_DUP), `seq 3→3`. Exactly-once.

## E3c same-key accumulation

Second SCHED_A is ordinal on the **current** heap (66,67,65), not a host
remap onto original 65,66,67.

| CLASS_ID | PRIOR_BEFORE | ORDINAL_REWARD | PRIOR_AFTER | SCORE |
|----------|--------------|----------------|-------------|-------|
| 66 | +2 | −1 | +1 | 17 |
| 67 |  0 | +2 | +2 | 18 |
| 65 | −1 |  0 | −1 | 15 |

`c7seq=6` (3 keys × 2 updates). No new allocation. Top-K **67@18, 66@17, 65@15**.

## E8 SchemaV2 persist / kill / reload

- flush completed
- `bram_kill`: pri66=0, TOP1=65 (working set hidden)
- reload: pri 65=−1, 66=+1, 67=+2; Top-K **67@18, 66@17, 65@15**
- `PERSIST_RELOAD_MATCH=1`

## E4 zero/neutral (clean store)

G2 `reward=0` → delta 0. After `[0,0,0]` train: priors 0,0,0.
Ranking remains 65,66,67 @16. No unexplained improvement.

Note: `train_reset` is epoch-bump only; a later same-key update restamps
and keeps `pri`. Independent controls used DUT rst + empty DDR (P_CLR).
Not a G2 redesign.

## E5 shuffled SCHED_B = [+2, 0, −1]

| CLASS_ID | PRIOR | SCORE | RANK |
|----------|-------|-------|------|
| 65 | +2 | 18 | 0 |
| 66 |  0 | 16 | 1 |
| 67 | −1 | 15 | 2 |

Materially different stored priors and ranking vs SCHED_A (66 first).

## E6 context isolation CLASS_ID 58

Train chiller only, SCHED_CHILLER58 ordinal heap[1]=+2.

| query | CLASS_ID | key (subj,rel,obj) | hit | prior | score | TOP1 |
|-------|----------|--------------------|-----|-------|-------|------|
| chiller | 58 | 0x5443003A, 0x01, 0x01000000 | 1 | +2 | 10 | 58 |
| water chiller | 58 | 0x5443003A, 0x09, 0x01000001 | 0 | 0 | 16 | 58 (baseline) |

F2 CONTEXT_ALIAS = not triggered. `CONTEXT_LEAK_COUNT=0`.

## E7 held-out leak_chiller

Never trained. Top-K 68,69,70,71 @16. Priors 0. No unearned transfer.
This is contextual adaptation, not generalization.

## E9 store capacity 32

| query | unique keys (cumulative) | seq |
|-------|--------------------------|-----|
| chiller | 8 | 8 |
| water chiller | 16 | 16 |
| install chiller | 19 | 19 |
| leak chiller | 23 | 23 |
| air condenser | 31 | 31 |
| supply duct | 32 then NAK | 32 |

- STORE_DEPTH = 32
- N_UNIQUE_LEARN_KEYS = 32
- FIRST_NAK_AT_WRITE = 33
- NAK_COUNT = 1
- QUERIES_TO_FIRST_NAK = 6
- UPDATE_EXISTING_WHILE_FULL: re-train chiller `seq 32→40`, NAK stayed 1

Capacity exhaustion is a resource horizon, not a mapping failure.

## Root-B / R1 / R2

- store success ⇔ BRAM write (`persist_done` on A/B/zero/fill)
- store-full new key: `persist_nak`, not `persist_done`
- duplicate reward: ACK_DUP, seq unchanged
- G1 ACK_CONSUME ≠ BRAM commit (dup consume does not write)
- host semantic counters = 0
- C7_ADDR last observe `03000400` (OBSERVE_ONLY)

## Aggregate metrics

```text
TOP1_CHANGED_COUNT        = 1   (install A; chiller 58 also flipped TOP1)
PAIRWISE_ORDER_CHANGES    = 2
CONTEXT_LEAK_COUNT        = 0
FREEZE_MUTATION_COUNT     = 0
DUPLICATE_UPDATE_COUNT    = 0   (dup observed as ACK_DUP, no extra write)
HOST_SEMANTIC_COUNTERS    = 0
STORE_OCCUPANCY_MAX       = 32
FIRST_NAK_AT_WRITE        = 33
PERSIST_RELOAD_MATCH      = 1
```

Chiller isolation also changed TOP1 57→58; install A is the preregistered
causal-flip count in the TB aggregate (1). Isolation TOP1 change is recorded
in E6.
