# BRAM WORKING-MEMORY SPEC — Native AI / Minesweeper Multi-Agent

> **Design spec (`A7-NATIVE-BRAM-WM-SPEC-v1`, NOT BOARD AUTHORITY).** Compliance vs measured evidence:
> `results/A7-NATIVE-GRAPH/STATUS/BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md`.
> Masterplan memory doctrine: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/08_MEMORY_ARCHITECTURE.md` and
> `00_CURRENT_AUTHORITY.md` §3–§5. **§45 `BRAM_WORKING_MEMORY_ARCH_PASS` is NOT declared.**

**Document ID:** `A7-NATIVE-BRAM-WM-SPEC-v1`  
**Target:** Digilent Arty A7-100T / xc7a100t  
**Status:** DESIGN SPEC / NOT YET BOARD AUTHORITY  
**Date:** 2026-08-21

---

# 0. Purpose

This document defines how BRAM should be used in the target Native AI architecture.

The key architectural decision is:

> **BRAM is not the long-term knowledge store. BRAM is the high-speed working-memory layer that holds the currently active context, top candidates, top evidence paths, frontier state, and pending learning updates. DDR is the persistent long-term knowledge store.**

This architecture is intended to maximize real FPGA parallelism:

```text
LUT / FF
→ parallel scoring, matching, ranking, control

BRAM
→ hot working set / active cognition / queues / Top-K

DDR
→ persistent knowledge graph / episodes / learned relations

LM-06
→ final language composition after retrieval
```

The specification also defines how training must change if the project adopts this working-memory architecture.

---

# 1. Scientific and engineering boundaries

The following distinctions are mandatory:

```text
BRAM cache != persistent knowledge
Top token != semantic truth
high score != learned fact
candidate != evidence
evidence != final answer
logical agent != physical FPGA agent
working-memory update != long-term learning update
```

The final Native AI release path must preserve:

```text
teacher = 0
external_LLM = 0
learn = 0
freeze = 1
```

during blind/release inference.

The host may provide:

```text
raw bytes/tokens
training documents
teacher questions
teacher scores/rewards during TRAIN
logging/display
```

The host must not compute:

```text
gradient
delta weights
winner
memory address
retrieval result
next token
final answer
```

for the final Native AI proof.

---

# 2. Current physical constraint

Current routed resource accounting indicates approximately:

```text
LM-06:
132 / 135 BRAM tiles

A0.3 encoder:
3 / 135 BRAM tiles

naive total:
135 / 135
```

Therefore the target working-memory architecture cannot simply instantiate an additional independent BRAM pool.

The final architecture must investigate one or more of:

```text
A. phase-based BRAM sharing
B. reduction of LM-06 BRAM footprint
C. migration of persistent state to DDR
D. very small L0 LUTRAM + shared BRAM pool
E. a combination of A–D
```

The preferred first hypothesis is:

> **Search/learning and LM generation can time-share physical scratch BRAM because their high-bandwidth scratch lifetimes need not overlap completely.**

This must be demonstrated by implementation and post-route evidence.

---

# 3. Memory hierarchy

Target hierarchy:

```text
                    ┌────────────────────┐
                    │        DDR3        │
                    │ Long-Term Knowledge│
                    └─────────┬──────────┘
                              │
                        burst / prefetch
                              │
               ┌──────────────┴──────────────┐
               │      SHARED BRAM POOL       │
               │   Active Working Memory     │
               └──────────────┬──────────────┘
                              │
        ┌─────────────────────┼──────────────────────┐
        ▼                     ▼                      ▼
  Candidate Buffer       Frontier / Top-K      Learning Buffer
        │                     │                      │
        └─────────────────────┼──────────────────────┘
                              ▼
                     Physical Agent PEs
                              │
                       EXPAND/HOLD/PRUNE
```

Optional L0:

```text
LUTRAM
→ tiny per-lane queue / score register / local candidate window
```

L1:

```text
shared BRAM
→ active query working set
```

L2:

```text
DDR
→ persistent graph and episodes
```

---

# 4. BRAM semantic role

BRAM should hold **Top Evidence**, not merely Top Tokens.

A weak representation:

```text
FPGA
LUT
routing
clock
configuration
```

is only a bag of tokens.

Preferred representation:

```text
EvidenceEntry:
    node_id
    subject_id
    relation_type
    object_id
    query_epoch
    path_id
    score
    confidence
    temporal_state
    source_episode
```

Example:

```text
FPGA
 --HAS-->
 LUT
score = 241
confidence = 228
```

and:

```text
FPGA
 --USES-->
 programmable_routing
score = 232
confidence = 219
```

The working-memory layer should preserve enough structure for the downstream language composer to reconstruct meaning.

---

# 5. Proposed logical BRAM regions

The shared working-memory pool should be logically divided into the following regions.

## 5.1 Query Context Region

Purpose:

```text
current user query
active topic
entity cues
intent cues
recent context
query epoch
```

Suggested fields:

```text
query_epoch
interaction_id
entity_cue
intent_cue
context_cue
topic_mask
history_digest
mode
```

This region is small and should remain resident for the lifetime of one interaction.

---

## 5.2 Candidate Buffer

Holds candidates fetched from DDR or generated by graph expansion.

Suggested record:

```text
CandidateEntryV1
{
    query_epoch
    path_epoch
    logical_agent_id
    node_id
    parent_node_id
    relation_type
    node_cue
    base_score
    valid
}
```

The candidate buffer must support:

```text
multi-write or banked writes
multi-read or wide read
ready/valid backpressure
no silent overwrite
```

---

## 5.3 Score Buffer

Stores scores produced by physical PEs.

Suggested score decomposition:

```text
entity_score
intent_score
relation_score
context_score
path_score
prior_score
contradiction_penalty
temporal_score   # optional, initially observability-only
total_score
```

Important:

```text
temporal_score
```

must not affect search decisions until a separate controlled experiment demonstrates benefit.

---

## 5.4 Frontier Buffer

Contains unresolved high-value paths.

The frontier is the "where to search next" memory.

Each entry:

```text
FrontierEntryV1
{
    query_epoch
    path_epoch
    logical_agent_id
    node_id
    parent_node_id
    depth
    score
    confidence
    status
}
```

Status:

```text
OPEN
HOLD
EXPANDED
PRUNED
STALE
```

The frontier must never confuse:

```text
PRUNED
```

with:

```text
DELETE KNOWLEDGE
```

Pruning is query-local.

---

## 5.5 Top-K Evidence Buffer

Contains the best evidence discovered so far.

This should be a **true global Top-K**, not pair winners.

Suggested K ladder:

```text
K = 4
K = 8
K = 16
```

Start with:

```text
K = 8
```

unless routing/quality tests show otherwise.

Evidence entry:

```text
TopEvidenceV1
{
    rank
    query_epoch
    node_id
    subject_id
    relation_type
    object_id
    source_episode
    score
    confidence
    path_depth
}
```

Requirements:

```text
exact ordering during baseline experiments
deterministic tie-breaking
no duplicate unless explicitly allowed
```

---

## 5.6 Learning Update Buffer

Learning should not immediately write every transient candidate to DDR.

Instead:

```text
PE/local learner
    ↓
pending update
    ↓
Learning Update Buffer
    ↓
validation / aggregation / confidence
    ↓
writeback to DDR
```

Suggested record:

```text
LearningUpdateV1
{
    query_epoch
    subject_id
    relation_type
    object_id
    delta_or_transition
    evidence_count
    teacher_reward
    native_confidence
    dirty
}
```

This region allows:

```text
coalescing repeated updates
reducing DDR writes
avoiding one-shot knowledge pollution
```

---

# 6. DDR long-term knowledge

DDR should be authoritative for persistent learned knowledge.

It should store:

```text
NodeRecordV1
EdgeRecordV1
EpisodeRecordV1
TopicShardV1
IndexRecordV1
```

## 6.1 NodeRecordV1

Example:

```text
node_id
node_type
topic_id
cue
confidence
adjacency_ptr
degree
version
```

## 6.2 EdgeRecordV1

Example:

```text
src_node
dst_node
relation_type
learned_weight
teacher_prior
positive_count
negative_count
last_update_epoch
```

## 6.3 EpisodeRecordV1

Example:

```text
episode_id
subject
relation
object
context
source_ref
answer_payload_ref
confidence
```

## 6.4 Required rule

There must be exactly one authoritative record layout.

No independent magic strides in:

```text
RTL
Python
frontend
DDR loader
testbench
```

All implementations must consume the same versioned schema.

---

# 7. Working-memory lifecycle

One query should follow:

```text
QUERY_BEGIN
    ↓
allocate query_epoch
    ↓
derive native query/context cues
    ↓
fetch coarse candidates from DDR
    ↓
load Candidate Buffer
    ↓
parallel scoring
    ↓
true Top-K
    ↓
store Top Evidence
    ↓
expand Top-K neighbors
    ↓
load next candidates
    ↓
repeat bounded rounds
    ↓
freeze final Top Evidence
    ↓
optional learning update
    ↓
commit dirty learned state to DDR
    ↓
LM generation
    ↓
QUERY_END
```

No unbounded graph traversal.

Search should have hard bounds:

```text
beam width
max degree
max depth
max candidates/query
max DDR bytes/query
```

---

# 8. Suggested initial search limits

Development defaults:

```text
beam_width = 8
max_degree = 8
max_depth = 4
top_k = 8
physical_lanes = 16 target
```

These are development values, not final truth.

They must be swept experimentally.

Hard stop:

```text
No hidden full scan.
```

The graph engine must not inspect all 800k episodes per query.

---

# 9. Physical BRAM architecture

Because physical BRAM is constrained, use a shared banked architecture.

Example:

```text
BRAM BANK 0
→ query context + control

BRAM BANK 1..N
→ candidate/frontier/evidence ping buffer

BRAM BANK N+1..M
→ candidate/frontier/evidence pong buffer

BRAM BANK M+1
→ update/writeback buffer
```

However, actual tile ownership must be determined after the LM-06 BRAM ownership audit.

The final target may instead be:

```text
PHASE SEARCH:
shared pool = graph working memory

PHASE GENERATE:
same physical pool = LM activation/tile scratch
```

---

# 10. Ping-pong buffering

Recommended dataflow:

```text
DDR fills PONG
while
PE array processes PING
```

then swap.

Benefits:

```text
overlap DDR traffic with compute
reduce PE starvation
enable long burst reads
hide part of DDR latency
```

Required telemetry:

```text
ping_busy_cycles
pong_fill_cycles
swap_count
buffer_empty_stall
buffer_full_stall
```

---

# 11. BRAM banking for physical agents

Do not connect 16 agents to a single-port memory and call the design parallel.

Required strategies:

```text
banking
replication of read-only query/context
multi-bank striping
wide-word broadcast
local per-lane registers/LUTRAM
```

Example:

```text
query context
→ broadcast to all lanes

candidate records
→ 16-bank interleave

lane i
→ bank i or deterministic bank map
```

Conflicts must be measured.

Metrics:

```text
bank_conflict_count
conflict_stall_cycles
effective candidates/cycle
```

---

# 12. BRAM and Top-K

Top-K should not consume large memory.

Preferred architecture:

```text
PE outputs
    ↓
comparator / bitonic network
    ↓
small register/FF Top-K state
    ↓
BRAM only stores full evidence payload
```

The rank/key path should stay close to LUT/FF for speed.

BRAM stores the payload referenced by the ranked IDs.

This prevents Top-K from becoming BRAM-port-bound.

---

# 13. BRAM and NTDE

NTDE should initially use BRAM only for sampled telemetry if needed.

Prefer cheap local state:

```text
prev_score
delta
zero-cross count
moving accumulator
```

in FF/LUTRAM.

If history is required:

```text
short ring buffer
```

may use BRAM/LUTRAM.

Do not allocate large BRAM history until the project proves the temporal history is useful.

---

# 14. Training architecture under the new memory model

If the new architecture is adopted, training should be redefined around:

```text
query-local exploration
teacher ranking/reward
parallel native scoring
local relation learning
confidence accumulation
persistent DDR promotion
```

This is different from blindly updating all weights for every observed token.

---

# 15. Teacher role

The Teacher AI may:

```text
read MD documents
create questions
create positive candidates
create hard negatives
assign relevance/ranking
assign relation labels
assign contradiction/bomb labels
create blind exam questions
```

The Teacher must not:

```text
send gradients
send delta weights
choose FPGA winner
choose DDR address
generate Native final answer during blind evaluation
```

Principle:

> **Teacher decides what to teach. FPGA decides how to learn.**

---

# 16. Recommended training item

A training sample should be structured approximately as:

```text
TrainingSampleV1
{
    raw_question
    source_topic
    candidate_set
    teacher_rank
    relation_labels
    hard_negatives
    expected_fact_ids   # auditor-only during exam
}
```

During TRAIN, the FPGA may receive:

```text
question
candidate/reward supervision
relation supervision
```

During BLIND_EXAM, it must receive only:

```text
question
```

---

# 17. Minesweeper learning rule

The game interpretation should be formalized as:

```text
high relevance
→ EXPAND

medium relevance
→ HOLD / continue search

low contextual relevance
→ PRUNE current path

hard contradiction
→ PRUNE + negative learning signal
```

A "bomb" is contextual:

```text
bomb(query, node, path)
```

not permanent:

```text
bomb(node)
```

Example:

```text
Q1 = "FPGA là gì?"
dog → prune
```

but:

```text
Q2 = "FPGA có thể nhận diện con chó không?"
dog → relevant
```

---

# 18. Learning promotion stages

Do not write every transient observation directly as long-term knowledge.

Use staged promotion:

```text
STAGE 0 — CANDIDATE
observed once

STAGE 1 — WORKING EVIDENCE
high score in current query

STAGE 2 — REPEATED EVIDENCE
confirmed across multiple questions/contexts

STAGE 3 — LEARNED RELATION
eligible for persistent DDR update

STAGE 4 — STABLE KNOWLEDGE
survives blind tests / contradiction checks
```

This reduces contamination from one bad teacher sample.

---

# 19. Suggested learning confidence

Example integer confidence:

```text
confidence ∈ [0, 255]
```

Possible update rule:

```text
positive confirmation:
confidence += small_step

hard negative:
confidence -= larger_step

contradiction:
confidence -= contradiction_step

repeat in diverse context:
confidence += diversity_bonus
```

All steps should be:

```text
integer
saturating
hardware-cheap
```

No floating point required.

This is only a candidate learning law and must be tested.

---

# 20. Parallel local learning

Reuse proven FPGA-native principles where possible:

```text
many local updates in parallel
small integer state
margin-triggered updates
bipolar/binary features
```

Avoid CPU-style sequential loops when the dependency structure permits parallel updates.

Physical claim rule:

```text
only routed independent simultaneous update logic
may be called physically parallel
```

---

# 21. When retraining is required

Retraining is required if any of the following changes:

```text
query representation law
relation representation
candidate scoring law
learning update law
confidence promotion rule
memory record semantics
teacher supervision format
```

Retraining is NOT automatically required for:

```text
purely lossless buffer changes
pipeline retiming
BRAM banking
DDR burst depth
cache replacement
Top-K implementation if semantics are identical
```

provided bit-exact functional equivalence is demonstrated.

---

# 22. Retraining protocol

If the project adopts the new Minesweeper/graph learning law:

## Phase T0 — Reset

```text
persistent learned graph = cleared
teacher ON
learning ON
```

Verify:

```text
no semantic ROM
no preloaded answer mapping
```

## Phase T1 — Foundation

Train:

```text
token/concept identity
basic relation types
sequence/context bindings
```

## Phase T2 — Topic curriculum

For each topic:

```text
definitions
components
mechanisms
comparisons
causal relations
hard negatives
contradictions
```

## Phase T3 — Context variation

Teach:

```text
paraphrases
word-order variation
multi-topic questions
distractors
rare wording
related-but-wrong concepts
```

## Phase T4 — Teacher ranking

Teacher provides:

```text
A > B > C > D
```

or integer relevance.

FPGA must choose/update internally.

## Phase T5 — Freeze

```text
teacher = 0
external_LLM = 0
learn = 0
freeze = 1
```

## Phase T6 — Blind exam

Use held-out questions.

Measure:

```text
retrieval accuracy
Top-K recall
hard-negative FP
contradiction avoidance
DDR bytes/query
candidate count/query
latency
```

## Phase T7 — Reset / retrain

Clear learned memory and train a different mapping/topic.

This proves mutable post-bitstream learning.

---

# 23. Training hard stops

The following immediately invalidate a Native AI learning proof:

```text
host computes winner
host supplies memory address
host computes gradient
host sends delta weights
host supplies precomputed semantic cue during final exam
host generates final answer
answer key visible during blind inference
semantic ROM maps prompt to answer
```

Teacher dependency is allowed during TRAIN.

Teacher dependency is forbidden during final Native inference.

---

# 24. BRAM training-mode behavior

TRAIN mode:

```text
Candidate Buffer active
Frontier active
Top-K active
Learning Update Buffer active
DDR writeback enabled
```

AUDIT mode:

```text
Candidate Buffer active
Frontier active
Top-K active
Learning Update Buffer disabled
DDR writeback disabled
```

BLIND_EXAM:

```text
Teacher blocked
Learning Update Buffer disabled
DDR writeback disabled
```

RELEASE:

```text
Teacher blocked
External LLM blocked
Learning disabled
Graph read-only
LM generation enabled
```

---

# 25. Dirty writeback policy

Avoid immediate DDR write for every local update.

Use:

```text
dirty bit
coalescing
thresholded commit
end-of-query commit
```

Candidate policy:

```text
if relation updated multiple times during one query:
    combine locally
    issue one DDR writeback
```

Measure:

```text
updates/query
DDR writes/query
write amplification
dirty occupancy
commit latency
```

---

# 26. Cache replacement policy

Initial recommendation:

```text
query-local reset
```

for Candidate/Frontier buffers.

For reusable graph cache:

start with:

```text
direct-mapped
or
small set-associative
```

Do not begin with a complex LRU unless measurements justify it.

Measure:

```text
hit rate
conflicts
LUT cost
BRAM cost
timing
```

---

# 27. Performance counters

The working-memory subsystem should expose at least:

```text
cycles_total

candidate_load
candidate_evict

frontier_push
frontier_pop
frontier_full

topk_insert
topk_replace

learning_updates
learning_coalesced
dirty_writebacks

ddr_reads
ddr_writes
ddr_read_bytes
ddr_write_bytes

cache_hit
cache_miss

buffer_empty_stall
buffer_full_stall
bank_conflict
```

Per physical lane:

```text
lane_busy[i]
lane_stall[i]
lane_candidates[i]
```

---

# 28. Required BRAM ownership report

Before full integration, generate:

```text
BRAM_OWNERSHIP_POST_ROUTE.md
```

Required columns:

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? |
|---|---:|---|---|---|---|---|

The report must include:

```text
LM-06
encoder
graph
router
episodic memory
FIFOs
MIG-related buffers
debug
```

No full integration claim without this report.

---

# 29. Shared-BRAM phase arbitration

If phase sharing is implemented, use an explicit owner FSM:

```text
BRAM_OWNER_RESET
BRAM_OWNER_GRAPH
BRAM_OWNER_LM
BRAM_OWNER_MAINTENANCE
```

Hard invariant:

```text
exactly one writer authority per physical bank per cycle
```

Add assertions:

```text
no dual-owner write
no ownership transition with outstanding write
no LM read during graph rewrite unless explicitly safe
```

---

# 30. Phase transition protocol

GRAPH → LM:

```text
1. stop new graph requests
2. drain pipelines
3. commit/hold required evidence
4. complete dirty writebacks
5. snapshot final Top-K evidence
6. assert graph_quiescent
7. transfer BRAM ownership
8. start LM generation
```

LM → GRAPH:

```text
1. stop token generation
2. drain LM memory operations
3. assert lm_quiescent
4. transfer BRAM ownership
5. restore graph working-memory metadata
6. begin next query
```

If evidence must survive LM ownership, it should be:

```text
copied to DDR
or
stored in a non-shared small register/LUTRAM area
```

before ownership transfer.

---

# 31. BRAM budgeting

Until post-route proves otherwise, use a conservative rule:

```text
Do not design against 135/135 as a target.
```

Preferred integration objective:

```text
<= 130 BRAM
```

if feasible, to preserve implementation margin.

This is an engineering objective, not a scientific hard stop.

Actual hard device constraint:

```text
BRAM <= 135
```

---

# 32. Candidate capacity examples

If one candidate record is:

```text
16 bytes
```

then:

```text
256 candidates = 4 KiB
512 candidates = 8 KiB
1024 candidates = 16 KiB
```

If an evidence entry is:

```text
32 bytes
```

then:

```text
Top-8  = 256 bytes
Top-16 = 512 bytes
```

Therefore Top-K itself is tiny.

The large working-memory cost is more likely:

```text
candidate/frontier buffers
prefetch blocks
LM activation scratch
```

not Top-K metadata.

This is why full BRAM ownership auditing is mandatory.

---

# 33. Recommended first BRAM experiment

Create:

```text
A7-BRAM-WM-00
```

Goal:

> Prove the working-memory concept independently of LM-06.

Implement:

```text
16 physical candidate lanes
256-entry candidate buffer
64-entry frontier
Top-8 evidence
32-entry learning update buffer
DDR-backed synthetic graph
```

Use LUTRAM where beneficial.

Measure:

```text
LUT
FF
BRAM
DSP
WNS
TNS
lane utilization
DDR traffic
cycles/query
```

No semantic claim.

---

# 34. Second BRAM experiment

Create:

```text
A7-BRAM-WM-01
```

Goal:

> Demonstrate ping-pong DDR → working-memory feeding.

Test:

```text
burst sizes:
1 / 4 / 8 / 16 records

outstanding requests:
1 / 2 / 4 / 8
```

Measure:

```text
effective GB/s
PE stall fraction
working-buffer occupancy
bank conflicts
```

---

# 35. Third BRAM experiment

Create:

```text
A7-BRAM-WM-02
```

Goal:

> Demonstrate graph/LM phase ownership on the same BRAM pool.

First use a synthetic LM scratch consumer if full LM-06 integration is too large.

Required proof:

```text
GRAPH writes pattern A
→ ownership transfer
LM writes/reads pattern B
→ ownership transfer
GRAPH state restored or correctly reloaded
```

Zero corruption.

---

# 36. Fourth BRAM experiment

Create:

```text
A7-BRAM-WM-03
```

Goal:

> Integrate actual LM-06 scratch ownership without changing frozen LM-06 functional law.

This is a new integration implementation.

Do not overwrite the frozen LM-06 bitstream or closeout.

---

# 37. Training experiment under the new law

Protocol (frozen): `docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md`.

Create a separate branch:

```text
A7-NATIVE-GRAPH-TRAIN-V2
```

Do not overwrite the old encoder/graph evidence. Plumbing-only changes do **not** retrain. Law / representation / promotion / prune-that-learns **do** retrain from zero; keep the old model as control. Same curriculum first.

First corpus:

```text
20 facts
```

Then:

```text
40 facts
```

Only after teacher-off pass:

```text
256
4k
16k
65k
262k
800k
```

---

# 38. Training quality gates

For every training scale:

```text
teacher-on acquisition
teacher-off retrieval
hard-negative rejection
contradiction handling
held-out paraphrase
reset/retrain
```

Record:

```text
Top1
TopK recall
MRR or rank
hard-negative FP
miss rate
candidate count/query
DDR reads/query
DDR writes/train
latency/query
```

Do not promote merely because training loss improves.

---

# 39. Relation learning is more important than token frequency

Token frequency may be a feature.

It must not be the semantic authority.

Example:

```text
"FPGA is not a CPU"
```

The word:

```text
not
```

may be rare but semantically decisive.

Therefore learning should preserve:

```text
entity
relation
direction
context
negation/contradiction
sequence
```

not merely token co-occurrence.

---

# 40. Minimum relation vocabulary

Start with a small relation set:

```text
IS_A
HAS
PART_OF
USES
CAN_BE
CAUSES
COMPARES_WITH
SUBJECT_OF
OBJECT_OF
BEFORE
AFTER
CONTRADICTS
RELATED_TO
```

This vocabulary may later be learned/expanded, but V1 should remain bounded and hardware-manageable.

---

# 41. Recommended priority from current project state

Before BRAM optimization is treated as the only next task, the project must still resolve:

```text
P0 true Top-K correctness
P0 lossless flow control

P1 wide physical-lane dispatch
P1 query/path epoch ownership
P1 complete TermGen

P2 DDR locality/burst/prefetch

P3 shared BRAM architecture
```

Therefore BRAM work should proceed as a parallel architecture lane, but it should not hide upstream correctness defects.

---

# 42. Hard-stop summary

## BRAM hard stops

```text
BRAM > 135
→ FAIL

dual ownership of one BRAM bank
→ FAIL

silent candidate overwrite
→ FAIL

dirty learned state lost without explicit policy
→ FAIL

persistent graph stored only in volatile working memory
→ FAIL
```

## Training hard stops

```text
host computes update
→ FAIL

teacher present during blind inference
→ FAIL

answer key visible during retrieval
→ FAIL

hardcoded prompt→answer mapping
→ FAIL

query-scoped prune deletes global knowledge
→ FAIL
```

## Scientific hard stops

```text
high score == semantic truth
→ FALSE

wave similarity == semantic equivalence
→ FALSE

working memory == long-term memory
→ FALSE

logical agents == physical agents
→ FALSE
```

---

# 43. Final target architecture

```text
USER QUERY
    ↓
FPGA Native Encoder
    ↓
Query / Intent / Context Cues
    ↓
01R-style coarse routing
    ↓
DDR topic/index fetch
    ↓
SHARED BRAM WORKING MEMORY
    │
    ├─ Candidate Buffer
    ├─ Frontier
    ├─ Score Buffer
    ├─ Top-K Evidence
    └─ Pending Learning Updates
    ↓
16+ Physical Parallel Agent PEs
    ↓
EXPAND / HOLD / PRUNE
    ↓
learned relation updates
    ↓
DDR long-term knowledge
    ↓
freeze Top Evidence
    ↓
shared BRAM ownership → LM phase
    ↓
LM-06 language composition
    ↓
FPGA TOKEN OUTPUT
```

The central design principle is:

> **DDR remembers. BRAM thinks. LUT/FF search and learn. LM-06 speaks.**

---

# 44. Next recommended implementation branch

Recommended new branch/worktree:

```text
arch/bram-working-memory-v1
```

First task:

```text
A7-BRAM-WM-00
```

Scope:

```text
256 candidate entries
64 frontier entries
Top-8 exact evidence
32 pending updates
16 physical PE interface
synthetic DDR-backed graph
PERFMON counters
```

Do not integrate LM-06 in WM-00.

First prove:

```text
correct
lossless
bankable
burst-feedable
measurable
```

Then proceed to BRAM ownership sharing.

---

# 45. Acceptance definition

`BRAM_WORKING_MEMORY_ARCH_PASS` requires:

```text
1. exact Top-K semantics;
2. no silent data loss;
3. query/path scoped state;
4. persistent knowledge in DDR;
5. working-memory buffers bounded;
6. multi-lane access demonstrated;
7. DDR/BRAM traffic measured;
8. post-route timing PASS;
9. BRAM ownership documented;
10. no violation of Native AI boundary.
```

Only after that should the design be considered ready for full Native AI integration.
