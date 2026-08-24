# BRAM RESET & RETRAIN PLAN — Native AI / Arty A7

**Document ID:** `A7-NATIVE-BRAM-RESET-v1`  
**Target:** Digilent Arty A7-100T / xc7a100t  
**Status:** DESIGN SPEC / NOT YET BOARD AUTHORITY  
**Date:** 2026-08-22

---

# 0. Goal

Define an efficient, hardware-safe reset architecture for Native AI working memory and learned state.

The central rule is:

> **Do not physically zero all BRAM on every reset. Use logical invalidation with epochs/generations for normal operation, and reserve physical scrub for verified retraining/reset proofs.**

Recommended two-layer model:

```text
FAST RESET
==========
epoch + generation + pointer invalidation

SLOW VERIFIED RESET
===================
parallel BRAM scrub + DDR scrub + verification
```

---

# 1. Reset levels

Use four explicit reset levels.

```text
RESET LEVEL 0 — QUERY RESET
    discard working set of current query only

RESET LEVEL 1 — SESSION RESET
    clear context/frontier/Top-K/pending work

RESET LEVEL 2 — TRAINING RESET
    invalidate all learned graph/episode state for a new training generation

RESET LEVEL 3 — HARD / VERIFIED RESET
    physically scrub trainable BRAM + learned DDR regions and verify
```

These levels must not be conflated.

---

# 2. Normal BRAM reset should not erase every payload word

Example: Candidate Buffer with 256 entries.

Avoid:

```text
for i = 0..255:
    BRAM[i] = 0
```

Preferred:

```text
candidate_head  = 0
candidate_tail  = 0
candidate_count = 0
query_epoch    += 1
```

Old payload bits may remain physically present, but they are no longer authoritative.

Each entry is valid only if:

```text
entry.valid
&&
entry.query_epoch == active_query_epoch
&&
entry.training_generation == active_training_generation
```

This makes normal reset nearly constant-time.

---

# 3. Epoch and generation fields

Every query-scoped work item should carry:

```text
query_epoch
path_epoch
training_generation
logical_agent_id
```

Suggested widths:

```text
query_epoch         >= 16 bit
path_epoch          >= 16 bit
training_generation >= 32 bit
```

Example:

```text
CandidateEntry {
    valid
    query_epoch
    path_epoch
    training_generation

    node_id
    parent_node_id
    logical_agent_id
    score
    ...
}
```

---

# 4. Prevent epoch wrap from resurrecting stale data

Epoch wrap must never silently make old memory valid again.

For example:

```text
255 → 0
```

with an 8-bit epoch is unsafe.

Required policy:

```text
if query_epoch wrap is imminent:
    perform scrub/invalidation maintenance
    reset epoch safely

if training_generation wrap is imminent:
    require hard maintenance reset
```

A 16-bit query epoch and 32-bit training generation make wrap rare enough for practical use, but the behavior must still be defined.

---

# 5. QUERY_RESET

A new user query should use the lightest reset.

On `RESET_QUERY`:

```text
active_query_epoch++

candidate_head  = 0
candidate_tail  = 0
candidate_count = 0

frontier_head   = 0
frontier_tail   = 0
frontier_count  = 0

topk_valid      = 0
agent_job_valid = 0

clear short NTDE history
clear query-local context
```

Do NOT reset:

```text
knowledge graph
learned relations
episodes
long-term confidence
LM-06 weights
frozen RTL state
```

Flow:

```text
QUERY N done
   ↓
increment query_epoch
   ↓
old paths become stale
   ↓
QUERY N+1 begins
```

---

# 6. SESSION_RESET

Use when ending or abandoning an interaction/session but keeping long-term knowledge.

Reset:

```text
query context
candidate buffers
frontier
Top-K
logical-agent queues
temporary context binding
NTDE short history
pending non-committed work according to reset policy
```

Keep:

```text
persistent graph
episodes
stable learned confidence
LM-06 frozen backbone
```

---

# 7. TRAINING_RESET

Use when starting a new training generation with the same architecture.

On `RESET_TRAIN`:

```text
active_training_generation++
```

Invalidate:

```text
learned graph edges belonging to old generation
learned episode bindings
confidence/promotion state
pending learning updates
dirty metadata
query/session state
```

DDR records may remain physically present, but are invisible if:

```text
record.training_generation != active_training_generation
```

This allows very fast logical restart even with large DDR datasets.

---

# 8. HARD / VERIFIED RESET

For scientific proof of retraining from zero, provide:

```text
RESET_TRAIN_HARD
```

Required sequence:

```text
1. BLOCK new query input
2. BLOCK new learning
3. drain PE pipelines
4. drain Top-K/frontier
5. resolve/cancel pending learning writes according to policy
6. wait for DDR transactions to complete
7. acquire BRAM/DDR reset ownership
8. clear working-memory metadata
9. physically scrub trainable BRAM regions
10. physically scrub learned DDR regions
11. verify reset
12. allocate fresh generation
13. release memory ownership
14. report RESET_VERIFY_PASS
```

Teacher training must not restart until verification succeeds.

---

# 9. Do not erase LM-06 during Native knowledge reset

Separate model state into:

```text
FROZEN / IMMUTABLE
------------------
LM-06 backbone weights
frozen RTL law
frozen routing semantics where applicable

TRAINABLE / RESETTABLE
----------------------
encoder weights if enabled
learned graph relations
episodic bindings
confidence state
promotion state
working-memory metadata
```

A Native knowledge reset must not erase the LM-06 frozen backbone unless a separate experiment explicitly changes the backbone.

---

# 10. BRAM ownership during reset

If BRAM is time-shared between graph search and LM generation, reset must be an explicit third owner.

Use:

```text
BRAM_OWNER_GRAPH
BRAM_OWNER_LM
BRAM_OWNER_RESET
```

Hard invariant:

```text
exactly one write authority per physical BRAM bank per cycle
```

Never allow:

```text
GRAPH write + RESET write
```

or:

```text
LM write + RESET write
```

to the same bank in the same cycle.

---

# 11. Reset controller FSM

Recommended FSM:

```text
IDLE
 ↓ reset_req

BLOCK_INPUT
 ↓

DRAIN_PE
 ↓

DRAIN_FRONTIER
 ↓

WAIT_DDR_IDLE
 ↓

TAKE_MEMORY_OWNERSHIP
 ↓
              ┌────────────────────┐
QUERY_RESET → INVALIDATE_ONLY      │
SESSION     → INVALIDATE_SESSION   │
TRAIN_RESET → GENERATION_BUMP      │
HARD_RESET  → SCRUB_MEMORY         │
              └────────────────────┘
 ↓

VERIFY
 ↓

RELEASE_MEMORY
 ↓

RESET_DONE
```

Suggested state names:

```text
RST_IDLE
RST_BLOCK_INPUT
RST_DRAIN_PE
RST_DRAIN_QUEUES
RST_WAIT_DDR
RST_TAKE_OWNER
RST_INVALIDATE
RST_SCRUB_BRAM
RST_SCRUB_DDR
RST_VERIFY
RST_RELEASE
RST_DONE
RST_ERROR
```

---

# 12. Reset interface

Suggested commands:

```text
reset_req

reset_level:
    RESET_QUERY
    RESET_SESSION
    RESET_TRAIN
    RESET_HARD
```

Suggested status:

```text
reset_busy
reset_done
reset_error

graph_quiescent
lm_quiescent
ddr_idle
all_lanes_idle
all_queues_empty
```

State IDs:

```text
active_query_epoch
active_training_generation
```

---

# 13. Dirty-state policy

A reset request may arrive while learned state is dirty.

Do not use one ambiguous reset behavior.

Provide explicit policies:

## RESET_ABORT

```text
discard uncommitted query-local learning
invalidate pending update buffer
do not commit those updates to DDR
```

## RESET_COMMIT

```text
stop new updates
drain learning pipeline
coalesce pending updates
commit dirty state to DDR
then reset working memory
```

For scientific retraining from zero:

```text
RESET_HARD
```

must remove old learned state regardless of prior dirty state.

---

# 14. Reset table

| State | Query Reset | Session Reset | Training Reset | Hard Scrub |
|---|---:|---:|---:|---:|
| Query context | clear | clear | clear | clear |
| Candidate buffer | invalidate | invalidate | invalidate | scrub optional |
| Frontier | invalidate | invalidate | invalidate | scrub optional |
| Top-K evidence | clear valid | clear | clear | scrub optional |
| PE jobs | clear | clear | clear | clear |
| NTDE short history | clear | clear | clear | clear |
| Pending updates | keep/abort by policy | clear | clear | scrub |
| Dirty bits | policy | clear safely | clear | scrub |
| Learned graph | keep | keep | invalidate | scrub DDR |
| Episodes | keep | keep | invalidate | scrub DDR |
| Confidence state | keep | keep | invalidate | scrub |
| Encoder trainable state | keep | keep | depends experiment | optional scrub |
| LM-06 frozen weights | keep | keep | keep | keep |

---

# 15. Physical BRAM scrub should exploit bank parallelism

If physical scrub is required, do not clear one bank completely before moving to the next.

If banks are independent:

```text
cycle 0:
BANK0[address0] = 0
BANK1[address0] = 0
BANK2[address0] = 0
...
BANKN[address0] = 0

cycle 1:
BANK0[address1] = 0
BANK1[address1] = 0
...
```

This uses true FPGA parallelism.

Avoid:

```text
clear all BANK0
then clear all BANK1
then clear all BANK2
```

unless banking/resource constraints require it.

---

# 16. Scrub-rate formula

For:

```text
B = number of BRAM banks scrubbed in parallel
D = maximum depth in words
fclk = scrub clock
```

ideal BRAM scrub time is approximately:

```text
T_scrub ≈ D / fclk
```

if all B banks scrub one address per cycle in parallel.

If banks are scrubbed sequentially:

```text
T_scrub ≈ B × D / fclk
```

Therefore parallel bank scrub can reduce reset latency by roughly the bank count.

Actual timing must be measured after implementation.

---

# 17. DDR learned-state reset

For large learned memory, use two modes.

## Fast logical DDR reset

```text
active_training_generation++
```

No full memory wipe required immediately.

Records from old generations are ignored.

## Verified physical DDR scrub

For scientific retrain proof:

```text
write reset pattern / zero to learned DDR region
```

then verify.

DDR scrub should operate as long bursts, not random single-word writes.

Recommended:

```text
contiguous learned regions
burst writes
multiple outstanding transactions if safe
```

---

# 18. DDR region layout to support reset

Persistent learned memory should be partitioned explicitly:

```text
DDR
│
├── FROZEN_REGION
│   LM or fixed assets that reset must not alter
│
├── GRAPH_LEARNED_REGION
│
├── EPISODE_LEARNED_REGION
│
├── INDEX_LEARNED_REGION
│
├── CONFIDENCE_REGION
│
└── SCRATCH / CACHE BACKING REGION
```

The reset controller receives region boundaries from a versioned memory map.

Never hardcode undocumented addresses in multiple RTL/Python files.

---

# 19. Reset verification

Hard reset completion must not mean merely:

```text
counter reached end
```

Verification should check at least:

```text
candidate_valid_count == 0
frontier_count == 0
topk_valid_count == 0
pending_update_count == 0
dirty_count == 0
old_generation_visible_count == 0
```

For physical scrub, additionally verify learned memory.

Possible strategies:

```text
full scan for small BRAM regions
CRC/checksum
sample + full metadata validation
full DDR scan for release proof if feasible
```

For the strongest scientific proof, use a full learned-region verification.

---

# 20. Stale-state protection

Every pipeline decision must verify ownership.

Example:

```text
if incoming.query_epoch != active_query_epoch:
    stale_drop++

if incoming.training_generation != active_training_generation:
    stale_drop++
```

No stale state may:

```text
modify Top-K
modify frontier
update graph
write episode state
affect final answer
```

Add assertions in XSim.

---

# 21. Query reset performance target

Normal query reset should be effectively constant-time from the perspective of buffer size.

Target:

```text
pointer reset
epoch bump
valid-mask clear
```

not O(number of entries).

Measure:

```text
cycles/query_reset
```

Goal:

```text
small fixed cycle count
```

rather than scaling with BRAM depth.

---

# 22. Training reset performance target

Logical training reset should also be near constant-time:

```text
generation bump
metadata reset
queue invalidation
```

Physical old state may remain until scrub/overwrite.

The important rule is:

> Old state must no longer have authority immediately after the generation changes.

---

# 23. Reset/retrain proof milestone

Create:

```text
A7-NATIVE-RESET-00
```

Protocol:

```text
TRAIN A
↓
teacher OFF
↓
retrieve A
↓
PASS

HARD RESET
↓
RESET_VERIFY_PASS

teacher OFF
query A
↓
A must NOT be retrievable from stale learned state

TRAIN B
↓
teacher OFF
↓
retrieve B
↓
PASS

query A
↓
must not leak stale A unless A was legitimately relearned
```

---

# 24. Strong mapping-swap proof

Use:

```text
TRAIN #1:
X → A

HARD RESET

TRAIN #2:
X → B
```

Final frozen test:

```text
query X
→ B
```

and verify:

```text
old A mapping does not leak
```

This is strong evidence that knowledge is mutable learned state rather than a hardcoded semantic ROM.

---

# 25. Recommended implementation sequence

```text
PHASE 1
Fix exact Top-K and lossless flow first

PHASE 2
Add query_epoch / path_epoch

PHASE 3
Add training_generation

PHASE 4
Implement Query Reset

PHASE 5
Implement Session Reset

PHASE 6
Implement Training Generation Reset

PHASE 7
Add BRAM Reset Owner FSM

PHASE 8
Implement Parallel Physical BRAM Scrub

PHASE 9
Implement DDR Learned-Region Scrub

PHASE 10
Implement RESET_VERIFY

PHASE 11
Run A → reset → B board proof
```

Do not start with a giant physical memory wipe.

---

# 26. PERFMON counters for reset

Add:

```text
reset_count_query
reset_count_session
reset_count_train
reset_count_hard

reset_cycles_last
reset_cycles_max

stale_drop
dirty_discard
dirty_commit

bram_scrub_words
ddr_scrub_bytes

reset_verify_fail
reset_owner_conflict
```

These counters should not sit on critical datapaths.

---

# 27. Hard stops

Immediate FAIL conditions:

```text
reset occurs while DDR write is outstanding
without an explicit commit/abort policy
→ FAIL

reset occurs while PE can still mutate learned state
→ FAIL

old generation becomes visible after reset
→ FAIL

query N state affects query N+1 without explicit context contract
→ FAIL

RESET_DONE asserted before reset verification completes
→ FAIL

hard reset reports PASS but stale fact is still retrievable
→ FAIL

reset wipes frozen LM-06 backbone
→ DESIGN ERROR

two owners write same BRAM bank in same cycle
→ FAIL
```

---

# 28. Recommended RTL modules

Suggested module decomposition:

```text
a7ng_reset_ctrl.sv
a7ng_epoch_mgr.sv
a7ng_bram_scrubber.sv
a7ng_ddr_scrubber.sv
a7ng_reset_verify.sv
a7ng_memory_owner.sv
a7ng_reset_perfmon.sv
```

Responsibilities:

## `a7ng_reset_ctrl`

Top-level reset FSM.

## `a7ng_epoch_mgr`

Owns:

```text
query_epoch
path_epoch generation
training_generation
```

## `a7ng_bram_scrubber`

Parallel bank scrub engine.

## `a7ng_ddr_scrubber`

Burst-clears learned DDR regions.

## `a7ng_reset_verify`

Checks post-reset invariants.

## `a7ng_memory_owner`

Arbitrates:

```text
GRAPH
LM
RESET
```

## `a7ng_reset_perfmon`

Collects reset metrics.

---

# 29. Suggested verification tests

## TEST RST-01 — Query reset

```text
populate candidate/frontier/Top-K
RESET_QUERY
verify old entries invalid
verify persistent graph unchanged
```

## TEST RST-02 — Session reset

```text
populate context + queues
RESET_SESSION
verify all session-local state cleared
verify long-term learned state remains
```

## TEST RST-03 — Training generation

```text
train generation N
RESET_TRAIN
verify generation N records invisible
verify no full scrub required
```

## TEST RST-04 — Hard BRAM scrub

```text
fill trainable BRAM with nonzero pattern
RESET_HARD
verify scrub pattern/zero
```

## TEST RST-05 — DDR scrub

```text
fill learned DDR regions
RESET_HARD
verify cleared region
verify frozen region unchanged
```

## TEST RST-06 — Reset under traffic

Inject reset during:

```text
candidate scoring
frontier activity
dirty update
DDR request
```

Verify deterministic drain/abort behavior.

## TEST RST-07 — Epoch wrap

Artificially force epoch near wrap.

Verify maintenance scrub behavior.

## TEST RST-08 — A→Reset→B

Full learning proof.

---

# 30. Final architecture

```text
                     USER / TRAINER
                           │
                           ▼
                    RESET COMMAND
                           │
                           ▼
                 ┌─────────────────┐
                 │   RESET CTRL    │
                 └────────┬────────┘
                          │
       ┌──────────────────┼───────────────────┐
       ▼                  ▼                   ▼
   EPOCH MGR        MEMORY OWNER         PERFMON
       │                  │
       │           GRAPH / LM / RESET
       │                  │
       ├──────────┬───────┴───────┬───────────┐
       ▼          ▼               ▼           ▼
 Candidate     Frontier         BRAM        DDR learned
  Buffer                         scrub        regions
       │                          │             │
       └──────────────────────────┼─────────────┘
                                  ▼
                          RESET VERIFY
                                  │
                                  ▼
                         RESET_VERIFY_PASS
```

---

# 31. Final recommendation

Use this policy:

```text
NORMAL QUERY:
    epoch/pointer reset

NORMAL SESSION:
    query/session invalidation

NEW TRAINING GENERATION:
    generation invalidation

SCIENTIFIC RETRAIN PROOF:
    parallel BRAM scrub
    + DDR learned-region scrub
    + verification
```

The governing principle is:

> **Physical remnants do not matter if they have no authority. Logical invalidation should be the fast path. Physical scrub is reserved for explicit, verified clean-state proofs.**

For the Native AI project, this is more scalable than zeroing every memory word on every reset, especially once persistent learned storage moves toward hundreds of thousands of DDR-backed episodes.
