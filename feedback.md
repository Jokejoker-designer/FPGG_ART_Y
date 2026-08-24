# FEEDBACK — A7 Native Graph / Native AI Current Audit

> **Design-input audit (2026-08-21).** Live execution and evidence status:
> `results/A7-NATIVE-GRAPH/STATUS/FEEDBACK_MD_COMPLIANCE.md` and
> `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md`.
> Masterplan authority: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md`.
> **§26 status summary below is stale** — do not use for NEXT gate selection; use `LOOP_STATE.json`.

**Date:** 2026-08-21  
**Scope:** Current `A7_NATIVE_GRAPH_CURSOR` project state, with emphasis on correctness, real FPGA parallelism, memory architecture, Native AI boundary, and the next justified engineering actions.

---

## 1. Executive verdict

The project has made meaningful progress, but the next milestone should **not** be full integration yet.

The most important current finding is:

> **The primary bottleneck is not raw FPGA compute capacity. It is correctness and dataflow efficiency: exact Top-K selection, lossless flow control, wide dispatch to the physical lanes, query/path ownership, DDR locality, and only after that BRAM integration.**

The current design already contains useful FPGA-native building blocks and routed evidence, but some blocks are still prototypes and must not be interpreted as final Native AI capability.

The correct development order is:

```text
CORRECTNESS
    ↓
LOSSLESS DATAFLOW
    ↓
REAL MULTI-LANE UTILIZATION
    ↓
TERM GENERATION
    ↓
DDR FEEDING / LOCALITY
    ↓
FRONTIER / SEARCH ARCHITECTURE
    ↓
SHARED BRAM / DDR INTEGRATION
    ↓
NATIVE QUERY / ATTENTION
    ↓
TEACHER-OFF RETRIEVAL
    ↓
LM-06 ACTIVE COMPOSITION
    ↓
NTDE TEMPORAL INTELLIGENCE
    ↓
800k SCALE
```

Do not reverse this order.

---

# 2. Evidence status

## 2.1 What is currently supported

Current project evidence supports:

- routed parallel scorer prototypes;
- routed Top-K/frontier prototype;
- routed DDR/hotset smoke infrastructure;
- Python contracts/tests;
- proof that the FPGA can host significant parallel logic;
- proof that the project architecture is modular enough for worktree-based development.

## 2.2 What is not yet supported

The current project does **not** yet prove:

- exact global Top-8 selection;
- lossless continuous 16-lane search;
- 16 fully utilized physical agents;
- 1.6G end-to-end graph candidates/s;
- full Native AI integrated fit;
- Kidi teacher-off native retrieval;
- LM-06 active final-answer composition;
- 800k-episode graph scaling;
- NTDE temporal features improving semantic search.

The distinction must remain:

```text
FITS != RUNS != TRAINS != CONVERGES != USEFUL
```

and also:

```text
16 instantiated lanes != 16 busy lanes
logical agents != physical FPGA agents
score composition != complete candidate scoring
packet composition != LM generation
test harness PASS != Native retrieval PASS
```

---

# 3. P0 — Exact Top-K correctness

## Finding

The current `a7ng_topk.sv` behavior is effectively:

```text
candidate 0 vs 1  → keep one
candidate 2 vs 3  → keep one
...
candidate14 vs15 → keep one
```

This produces **eight pair winners**, not the true global Top-8 of sixteen candidates.

Example:

```text
pair 0:
100
99

pair 1:
10
9
```

A true Top-8 selector can retain both `100` and `99`.

A pair-winner selector cannot.

## Severity

**SEV-0 / correctness blocker**

## Required action

Create a repair branch/milestone:

```text
NG-02R-TOPK
```

Evaluate exact implementations:

1. bitonic 16→8 network;
2. exact partial-selection network;
3. multi-input systolic priority queue.

## Hard stop

Create a Python oracle and test:

```text
>= 100,000 randomized vectors
signed scores
ties
valid masks
deterministic tie-breaking
```

Requirement:

```text
RTL Top-8 == Python oracle Top-8
```

for every case.

One mismatch:

```text
FAIL
```

No approximation is allowed in this milestone.

---

# 4. P0 — Lossless flow control

## Finding

The current NG02 pipeline can accept/produce data under assumptions that are too weak for sustained multi-lane operation.

The current structure risks data loss if a new scorer batch arrives while previous winners are still being transferred into the frontier.

The board smoke pattern may not expose this because traffic is sparse.

## Severity

**SEV-0 / correctness blocker**

## Required invariant

For every accepted candidate:

```text
accepted
=
completed
+ queued
+ intentionally_pruned
+ in_flight
```

No candidate may disappear silently.

## Required action

Add explicit lossless flow control:

```text
scorer
  ↓ ready/valid
Top-K
  ↓ ready/valid
winner buffer
  ↓ ready/valid
frontier
```

Use skid/elastic buffers if necessary.

## Hard stop

Randomized backpressure test:

```text
>= 100,000 cycles
```

Require:

```text
DROP = 0
DUPLICATE = 0
UNEXPLAINED REORDER = 0
```

---

# 5. P1 — Physical parallelism is currently underfed

## Finding

The multi-agent scheduler currently dispatches at most about one logical job per cycle.

With 16 physical lanes at 100 MHz:

```text
ideal lane service capacity:
16 × 100M
= 1.6G lane operations/s
```

But a one-job-per-cycle dispatcher provides:

```text
100M jobs/s
```

which can feed only approximately:

```text
1 / 16 = 6.25%
```

of the theoretical lane capacity if it is the only dispatch path.

This is the clearest example of an FPGA design accidentally being used like a sequential CPU scheduler.

## Required action

Do **not** add more PEs yet.

Develop a parameterized dispatch ladder:

```text
1-way
4-way
8-way
16-way
```

Use:

```text
banked work queues
credit/backpressure
multi-grant allocator
lane availability bitmap
simultaneous enqueue/dequeue
fair scheduling
```

## Required telemetry

```text
lane_busy[16]
jobs_per_cycle
scheduler_idle
scheduler_conflict
queue_occupancy
queue_full
starvation_count
```

## Development gate

With all candidate data already local/on-chip:

```text
average physical lane utilization >= 80%
```

is a good development target before considering more lanes.

This is not a scientific law, but it is a useful engineering gate.

---

# 6. P1 — Query/path ownership and stale work

## Finding

A logical context can become inactive while old queue entries belonging to that context still remain in the system.

Similarly, delayed path/query results may arrive after a new query has begun.

This can cause stale state to affect the wrong interaction.

## Required architecture

Every work item should carry:

```text
query_epoch
path_epoch
logical_agent_id
```

On pop/decision:

```text
if item.query_epoch != active_query_epoch:
    DROP_STALE
```

and similarly for path ownership.

## Important semantic rule

A contextual “bomb” means:

```text
PRUNE THIS PATH FOR THIS QUERY
```

It does **not** mean:

```text
delete semantic knowledge
kill the concept permanently
reset the AI
```

Example:

```text
"FPGA là gì?"
dog → irrelevant / prune
```

but:

```text
"FPGA có thể nhận diện con chó bằng camera không?"
dog → potentially relevant
```

Therefore bomb/prune state must be contextual and query-scoped.

---

# 7. P1 — Current 16 lanes are not yet 16 complete search engines

## Finding

The scorer currently receives already-computed score terms such as:

```text
entity
intent
relation
context
path
prior
contradiction
```

and composes them.

It does not yet fully compute:

```text
query-node similarity
Hamming distance
relation binding
intent similarity
context features
memory-derived features
```

Therefore:

```text
16 lanes @ 100 MHz
```

does not yet justify:

```text
1.6G complete graph candidates/s
```

## Required missing block

Create:

```text
TERMGEN
```

Candidate pipeline:

```text
query cue
node cue
relation cue
context cue
    │
    ├─ XOR/XNOR
    ├─ popcount
    ├─ relation binding
    ├─ intent/context feature extraction
    └─ path/history feature
            ↓
       scorer lane
```

Only after `TERMGEN + scorer + pipeline` is routed should the project claim complete candidate-scoring throughput.

---

# 8. Research direction — HDC / VSA-style primitives

A suitable research direction for TermGen is binary Hyperdimensional Computing / Vector Symbolic Architecture.

Useful primitives:

```text
BIND       = XOR
PERMUTE    = rotate
BUNDLE     = accumulate/vote
SIMILARITY = Hamming/popcount
```

This is attractive because it maps naturally to:

```text
LUT
FF
wide XOR
popcount trees
barrel/constant rotations
```

and does not require dense floating-point matrix multiplication.

Recommended cue-width ladder:

```text
64-bit
128-bit
256-bit
```

Start with 64-bit because existing routing primitives already use 64-bit cues.

Example relational encoding:

```text
REL =
ENTITY_FPGA
XOR ROTL(REL_IS_A)
XOR ROTL(PROGRAMMABLE_LOGIC)
```

Scientific hard stop:

```text
similar HDC cue
!=
proven semantic equivalence
```

Semantic usefulness must still be demonstrated using:

```text
teacher supervision
held-out queries
teacher-off retrieval
```

---

# 9. P2 — DDR is likely to starve the PE array

## Finding

The current shard-fetch path is effectively close to:

```text
issue one read
wait
receive response
fill
continue
```

This is not enough for a sustained 16-lane graph engine.

The project should expect memory movement, not LUT arithmetic, to become the next major bottleneck once scheduler correctness is fixed.

## Required development order

```text
reduce candidate count
↓
increase locality
↓
burst DDR
↓
double buffer
↓
multiple outstanding reads
↓
measure PE utilization
↓
only then increase PE count
```

## Recommended architecture

```text
                 DDR
                  │
         burst node/edge records
                  │
           ┌──────┴──────┐
           │             │
       PING buffer    PONG buffer
           │             │
           └──────┬──────┘
                  │
        PE0 ... PE15 consume
```

While PEs process PING:

```text
DDR fills PONG
```

Then swap.

## Required experiments

Sweep:

```text
burst records:
1
4
8
16

outstanding reads:
1
2
4
8

graph degree:
4
8
16
```

Measure:

```text
effective GB/s
DDR bytes/query
cache hit rate
PE stall cycles
PE utilization
latency/query
```

Do not choose burst depth or outstanding depth by intuition.

---

# 10. P2 — Graph layout must be locality-aware

Avoid random pointer chasing when possible.

Recommended DDR organization:

```text
TOPIC SHARD
  ├─ compact node cues
  ├─ relation metadata
  ├─ adjacency blocks
  ├─ episode references
  └─ shard statistics
```

Favor:

```text
contiguous adjacency blocks
fixed or compact records
burst-friendly layout
```

over:

```text
random pointer
random pointer
random pointer
```

The final graph engine should exploit sparse search, not brute-force scan.

Hard stop:

```text
No hidden full scan of all episodes/nodes per query.
```

---

# 11. P2 — Frontier architecture needs a proper shootout

The current frontier is a coarse bucket priority structure.

This is useful as a prototype, but it is not equivalent to exact best-first ordering.

Recommended comparison:

```text
A. current/pipelined bucket frontier
B. exact systolic priority queue
C. two-level frontier:
   local per-lane queues
   + global merge
```

Use the same workload and measure:

```text
retrieval recall
hard-negative false positives
cycles/query
enqueue/cycle
dequeue/cycle
LUT
FF
WNS
TNS
```

Do not select the architecture before these measurements.

---

# 12. P2 — Memory record schemas must be frozen

Current project files show inconsistent assumptions around node/episode record stride.

Before scaling:

Create one authoritative schema:

```text
NodeRecordV1
EdgeRecordV1
EpisodeRecordV1
```

Each must define:

```text
exact byte size
field offsets
endianness
alignment
version
checksum/validation policy if needed
```

Add tests that serialize and deserialize golden records.

No RTL, Python, frontend, or DDR code should carry independent magic strides.

---

# 13. P2/P3 — Current memory banks are cache prototypes, not 800k storage

Small episode/index banks with whole-bank flush/reload are acceptable prototypes.

They must not be interpreted as the final 800k architecture.

Final memory model should become:

```text
DDR authoritative store
        │
        ├─ small clean cache
        ├─ dirty lines
        ├─ demand fill
        └─ writeback
```

Avoid:

```text
flush all 800k records
reload all 800k records
```

as a normal operation.

For the 800k phase, measure:

```text
episode_storage
index_storage
dirty writeback rate
DDR reads/query
DDR writes/train
cache hit rate
candidate count/query
overflow
miss rate
false positive rate
latency
```

---

# 14. P3 — BRAM integration remains a hard blocker

Current routed accounting:

```text
LM-06:
132 / 135 BRAM

Encoder:
3 / 135 BRAM
```

Together:

```text
135 / 135
```

This leaves no independent BRAM budget for router, graph cache, episodic memory, or integration FIFOs if these footprints remain unchanged.

Therefore final integration cannot be:

```text
instantiate four independent old blocks
```

The solution must be architectural.

## Most promising direction

Investigate **phase-based BRAM reuse**.

System phases naturally resemble:

```text
QUERY / RETRIEVE
       ↓
freeze evidence
       ↓
LM GENERATE
```

Graph retrieval and LM generation may not require the same scratch memories at the same moment.

Research:

```text
LM activation BRAM
↕ time-shared
graph hotset/frontier/cache
```

This can potentially reclaim far more usable memory than small local optimizations.

Do not modify the frozen LM-06 evidence bitstream.

Create a new integration experiment.

---

# 15. P3 — Audit LM-06 BRAM ownership before quantization

Before implementing W2/Q2, create a full BRAM ownership report:

```text
hierarchy
BRAM count
width
depth
lifetime
persistent/transient
quantizable?
DDR-backable?
shareable by phase?
```

Known major categories include:

```text
u_a
u_w
u_snap
```

The key question:

> Which BRAMs are weight staging, activation scratch, snapshot state, or persistent data?

Low-bit weights help only if the constrained memory is actually weight-related.

Do not assume weight quantization automatically solves the 132-BRAM problem.

---

# 16. P4 — Native attention is not yet fully native

Current prototype logic includes direct semantic scaffolding such as explicit cues for:

```text
FPGA
CPU
WHAT
HOW
VS
hardware
```

This is acceptable for interface/control prototyping.

It is not acceptable in the final Native AI authority path.

Final release path must be:

```text
user bytes/tokens
    ↓
FPGA encoder
    ↓
FPGA relation/context binder
    ↓
native query cues
    ↓
FPGA retrieval
```

not:

```text
host says:
entity = FPGA
intent = DEFINE
```

The host may send bytes/tokens.

The FPGA must derive attention/retrieval cues in the release proof.

---

# 17. P4 — Teacher firewall must become hardware-enforced

The release claim should not depend only on a Python launcher behaving correctly.

Introduce an explicit hardware mode FSM:

```text
TRAIN
AUDIT
BLIND_EXAM
RELEASE
```

Suggested permissions:

| Capability | TRAIN | AUDIT | BLIND_EXAM | RELEASE |
|---|---:|---:|---:|---:|
| Teacher supervision | yes | no | blocked | blocked |
| Learning updates | yes | no | no | no |
| External semantic cue | restricted | no | blocked | blocked |
| FPGA retrieval | yes | yes | yes | yes |
| FPGA token generation | optional | yes | yes | yes |

Release proof must explicitly show:

```text
teacher = 0
external_LLM = 0
learn = 0
freeze = 1
```

The host must not calculate:

```text
gradient
delta weight
winner
address
retrieval result
next token
final answer
```

---

# 18. P4 — Kidi-20 evidence needs a stronger native retrieval test

Current harness evidence should not be promoted to full retrieval proof unless it actually exercises:

```text
user query
→ native cue
→ route
→ graph traversal
→ contextual prune
→ evidence selection
```

The next Kidi test should:

1. train post-bitstream;
2. freeze;
3. disable teacher/external AI;
4. submit held-out queries;
5. let FPGA derive cues;
6. let FPGA retrieve;
7. compare only after retrieval finishes.

The answer key may be used by the auditor after inference.

It must not be visible to the Native AI during inference.

---

# 19. P5 — Evidence packet composer is not LM-06 integration

Packing evidence IDs into a byte structure is useful.

It is not equivalent to:

```text
retrieved evidence
→ LM-06 active forward path
→ generated FPGA tokens
```

The project should keep these labels separate:

```text
EVIDENCE_PACKET_PASS
```

versus:

```text
LM06_ACTIVE_INTEGRATION_PASS
```

The latter requires the actual frozen Transformer datapath to participate.

---

# 20. P6 — NTDE should begin as observability, not control

The Native Temporal Dynamics Engine is promising, but should not yet affect search decisions.

First deploy it as a measurement system.

Track:

```text
score[t]
path_score[t]
lane_utilization[t]
frontier_occupancy[t]
DDR_stall[t]
queue_pressure[t]
learning metrics[t]
```

Features:

```text
dx
d2x
zero crossings
moving mean
moving energy
peak-to-peak
trend
oscillation estimate
```

Nyquist–Shannon should be used only to answer:

> Are we sampling fast enough to observe meaningful dynamics without aliasing?

Do not claim:

```text
wave similarity
=
semantic similarity
```

If later data shows temporal features improve EXPAND/HOLD/PRUNE on held-out queries, open a separate controlled experiment.

---

# 21. Add a low-cost PERFMON now

A hardware performance monitor will pay for itself immediately.

Recommended counters:

```text
cycles_total

lane_busy[16]

candidates_in
candidates_out

topk_batches

frontier_push
frontier_pop
frontier_full

queue_full
queue_occupancy_accum

scheduler_grants
scheduler_idle
scheduler_starve

ddr_req
ddr_rsp
ddr_stall_cycles

cache_hit
cache_miss

prune_count
stale_drop
```

Per query report:

```text
lane_utilization
jobs/cycle
DDR_wait_fraction
cache_hit_rate
candidate_count
frontier_pressure
```

This is more useful than guessing where the bottleneck is.

---

# 22. Revised roadmap

## R0 — Audit freeze

Record current findings without rewriting old evidence.

Output:

```text
AUDIT_NATIVE_GRAPH/
```

with corrections and scope.

---

## R1 — Correctness repair

Implement:

```text
true global Top-8
lossless ready/valid
query/path epochs
stale-work rejection
```

Gate:

```text
CORRECTNESS_REPAIR_PASS
```

No partial pass.

---

## R2 — Real parallel dispatch

Implement:

```text
4-way
8-way
16-way dispatch
```

Measure actual utilization.

Gate:

```text
lossless
no starvation
routed timing pass
lane utilization measured
```

---

## R3 — TermGen

Implement full candidate feature generation:

```text
Hamming
relation binding
intent/context
path feature
```

Only then measure complete candidate throughput.

---

## R4 — DDR feeding

Add:

```text
burst
prefetch
double buffering
multiple outstanding reads
```

Select configuration by measured throughput/utilization.

---

## R5 — Frontier shootout

Compare:

```text
bucket
exact priority
two-level
```

using identical workloads.

---

## R6 — Shared-memory integration proof

Integrate:

```text
MIG
shared scratch
graph cache
DDR episode/index storage
LM memory arbitration
```

Gate:

```text
BRAM <= device
WNS >= 0
TNS = 0
DDR corruption = 0
ownership conflict = 0
```

---

## R7 — Native query/attention

Remove hardcoded semantic scaffolding from the authority path.

Replace with learned/native cue derivation.

---

## R8 — Real Minesweeper Kidi

Train:

```text
teacher supervision
```

Then freeze:

```text
teacher=0
external_LLM=0
learn=0
freeze=1
```

Test held-out native retrieval.

---

## R9 — Active LM-06 integration

Flow:

```text
query
→ native retrieval
→ structured evidence
→ LM-06
→ FPGA token output
```

Host displays only.

---

## R10 — NTDE research integration

Only after baseline search is correct and measurable.

Use temporal features first for diagnostics.

Promote them to search control only after controlled evidence.

---

## R11 — Scale ladder

Only after end-to-end correctness:

```text
20
40
256
4k
16k
65k
262k
800k episodes
```

At every scale measure:

```text
candidate count/query
DDR traffic/query
latency
false positives
misses
overflow
cache hit
training writes
retrieval quality
```

No hidden full scan.

---

# 23. Revised bottleneck priority

Current priority:

```text
P0  Top-K correctness
P0  Lossless flow control

P1  Wide dispatch / real lane utilization
P1  Query/path ownership
P1  Complete TermGen

P2  DDR locality / burst / outstanding reads
P2  Frontier throughput/ordering
P2  Memory record schema

P3  Shared BRAM/DDR integration

P4  Native attention
P4  Teacher-off retrieval proof

P5  Active LM-06 integration

P6  NTDE temporal intelligence

P7  800k scale
```

Do not optimize P6/P7 while P0/P1 remain open.

---

# 24. Immediate recommended Cursor task

The next engineering task should be:

```text
CORRECTNESS_REPAIR_PASS
```

not:

```text
integrate_fit
```

Recommended branch:

```text
fix/ng-correctness-dataflow
```

Required work:

```text
true Top-8
lossless flow
query/path epochs
wide dispatch scaffold
PERFMON
post-route report
```

Do not touch:

```text
NTDE decision law
encoder learning law
LM06 internals
01R/02M frozen semantics
800k scale
HNSW
approximate pruning
```

until correctness closes.

---

# 25. Final feedback

The current architecture is promising because the expensive resource on the FPGA is **not multiplication alone**. The project can exploit:

```text
LUT
→ Hamming / XOR / popcount / comparators / Top-K

FF
→ deeply pipelined agent/path state

BRAM/LUTRAM
→ hot working sets / queues / frontier

DDR
→ persistent graph / index / episodic knowledge

physical PE array
→ concurrent search/scoring

LM-06
→ final language composition
```

The main mistake to avoid now is to confuse:

```text
more instantiated lanes
```

with:

```text
more useful throughput
```

The most valuable milestone is to make the current 16-lane architecture:

```text
correct
lossless
fully fed
measurable
```

before increasing lane count.

Once that is achieved, the project can make an evidence-based decision about whether the Artix-7 should move toward:

```text
16
24
32
or more
```

physical lanes.

Until then, adding more lanes would mostly multiply idle hardware.

---

# 26. Status summary

```text
CURRENT PROJECT:
ACTIVE / NOT CLOSED

CURRENT NEXT GATE:
CORRECTNESS_REPAIR_PASS

FULL NATIVE AI:
NOT YET PROVEN

MULTI-AGENT PARALLELISM:
PROMISING, BUT UTILIZATION NOT YET PROVEN

DDR ARCHITECTURE:
PROTOTYPE / NEEDS BURST + PREFETCH + MULTI-OUTSTANDING

BRAM INTEGRATION:
HARD FUTURE BLOCKER

NATIVE ATTENTION:
PROTOTYPE / PARTLY HARDCODED

TEACHER-OFF RETRIEVAL:
NOT YET PROVEN END-TO-END

LM-06 ACTIVE COMPOSER:
NOT YET INTEGRATED

NTDE:
RESEARCH CANDIDATE; OBSERVABILITY FIRST

800k MEMORY:
FUTURE SCALE MILESTONE
```

The project should proceed with **correctness-first, bandwidth-aware, hardware-native parallelism**, not with CPU-style sequential scheduling and not by increasing PE count before the existing fabric is actually saturated.
