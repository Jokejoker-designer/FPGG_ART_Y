# 18 — Unified Native AI Final Blueprint V3.1

**Status:** FINAL CANDIDATE FOR EXECUTION AUTHORITY  
**Date:** 2026-09-04  
**Target:** Digilent Arty A7-100T — `xc7a100tcsg324-1`  
**Tool baseline:** Vivado 2026.1  
**Repository:** `Jokejoker-designer/FPGG_ART_Y`  
**Final objective:** `NATIVE_V1_MINI_AI_BOARD_PASS` under the unchanged Gate14 acceptance contract.

---

# 0. Authority and doctrine

This document is the final architecture/execution blueprint for converging the currently separate:

1. board-proven Gate14 learned C9 → LM-06 causal path; and
2. optimized DDR/SOA PHYS=4 retrieval path,

into **one FPGA-owned production datapath**.

Execution doctrine:

```text
Master Blueprint defines architecture.
Evidence defines truth.
Status files describe execution only when current.
Chat memory is not project authority.
```

Evidence hierarchy:

```text
BOARD
POST_ROUTE
MIG_XSIM
XSIM
OOC
RTL_FACT
ENGINEERING_ESTIMATE
HYPOTHESIS
```

Never promote weaker evidence into a stronger class.

Never infer:

```text
XSIM PASS      = BOARD PASS
RTL FACT       = XSIM PASS
IMPLEMENTED    = BOARD PROVEN
FAST           = ARCHITECTURALLY CORRECT
```

# 1. Source lineage and immutable history

## 1.1 Current lineage

```text
WORKTREE
D:/Jetking_sem4/SEM_4/arty-a7-online-lm-g14-preboard-00

BRANCH
grok-orch/g14-preboard-closure-00

EVIDENCE_HEAD
216bdc5bca9489963619e9bac566df7a3fc3b40e
DDR-EXPOSED-REMEASURE-00
RTL_EDIT = NO

PRODUCTION_RTL_ANCHOR
24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded
GLOBAL-SORT-FINAL-ONLY-00
```

`216bdc5` is a measurement/evidence head. The production RTL under that head is unchanged from `24dcdc1`.

Final integration must be created from an exact clean lineage, not by merging entire worktree directories.

## 1.2 Frozen historical board artifacts

Never program these again:

```text
1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
= historical Root-A / epoch causal board artifact

9CA2B30DCCD8A7AA2F348C3C4E2BDFCDAF9A9A67CBE0956EB0A8EBB532BADC80
= refused GUI OTHER artifact

F24150BDE6F69080B3C5865386C49F6F02300782FFB4037FAF044BB2099840F7
= frozen final-observability board artifact
= already programmed once
```

The next programmed bit must be a **new unique final candidate**.

# 2. Final claim boundary

If every final gate passes, the allowed claim is:

> An FPGA-native online-learning, memory-augmented small AI system on the
> Arty A7-100T, with an FPGA-owned query representation and sparse retrieval
> path, persistent episodic/relational knowledge in DDR, parallel graph
> scoring and exact Top-K retention, an 802,816-parameter Transformer
> backbone, post-bitstream contextual learning, teacher-off held-out
> retrieval, and FPGA-generated responses.

Do not claim:

```text
open-domain LLM
human-level intelligence
AGI
exact global nearest-neighbor across arbitrary overflowed buckets
800k physical agents
800k LM parameters
unbounded semantic generalization
```

Keep `P_LM = 802,816` separate from `N_EPISODES`, `N_NODES`, `N_EDGES`, and `N_CANDIDATES_PER_QUERY`.

# 3. Current evidence baseline

## 3.1 Board-proven causal path

Frozen board lineage proves the bounded Gate14 benchmark:

```text
20 fact A lessons
20 fact B lessons

teacher          = 0
external_LLM     = 0
forbidden host counters = 0

HOLD_A C9 = 8382238122802120

LM OUT:
HOLD_A = 653
UNREL  = 689
CONTRA = 237
HOLD_B = 60
```

Board evidence supports native learning causality, persistence, reset/forget/retrain, teacher-off inference, structured C9, LM-06 active response path, and FPGA-generated output. It does **not** prove an 800k retrieval architecture.

## 3.2 Optimized DDR/SOA path

Current MIG_XSIM lineage at `216bdc5`:

```text
PHYS = 4
WAVE = 16
N    = 64

T_QUERY:
1032
→ 744
→ 628
→ 500
→ 432
→ 397
→ 310 cycles

cand/cycle = 0.206452
```

Promoted microarchitecture:

```text
CUE overlap                  = PASS
local sort elide             = PASS
local sift-on-take           = PASS
local vector commit          = PASS
global merge_done split      = PASS
global final-wave-only sort  = PASS
```

DDR measurement:

```text
AR_TO_FIRST_R   = 24 cycles / wave
FETCH_SERVICE   = 44 / 42 / 42 / 42
II_STEADY       = 46
OUTSTANDING_HW  = 1
R_BACKPRESSURE  = 0
FIFO_HIGH_WATER = 1
AR              = 4/query
BEATS           = 64/query
BYTES           = 1024/query
```

This path still fetches all admitted records:

```text
candidates/query = N
DDR bytes/query  = 16*N
```

The current SOA admission policy is not acceptable for 800k.

# 4. Root architectural defect

The current SoC still contains two retrieval concepts.

```text
GATE14 CAUSAL BENCHMARK PATH
fixed query IDs
→ RTL-generated candidates / terms
→ bounded learned store
→ scorer
→ Min-heap
→ C9
→ LM-06
```

and:

```text
SOA PERFORMANCE PATH
fixed board-level cues
→ read every NodeRecord
→ TermGen / scorer
→ Local/Global Min-heap
→ existence result
```

Final architecture must contain:

```text
one raw query input
one FPGA-owned query representation
one sparse candidate stream
one scorer authority
one retained Top-K chain
one learned-state authority
one C9 evidence path
one LM response path
```

# 5. Final Native V1 scope lock

## 5.1 800k means persistent knowledge capacity

```text
N_EPISODES_TOTAL = 800,000 target
FULL_SCAN_800K   = NO
```

## 5.2 Online-learning scope for V1

Native V1 supports:

```text
STATIC / PRELOADED episode corpus up to 800k
+
ONLINE contextual learned deltas to existing nodes/edges/episodes
```

Dynamic online creation/insertion of arbitrary new episode records into the 800k corpus is **OUT OF SCOPE for Native V1 final closure**.

V1 therefore does not require online episode allocation, posting-page split/merge, directory rebalance, or dynamic corpus growth.

# 6. Unified production datapath

```text
RAW UART / APPLICATION QUERY TOKENS
              |
              v
FPGA QUERY REPRESENTATION FRONTEND
  deterministic Native-V1 feature law
  no host-provided entity/hash/shard/address
              |
              v
FPGA-OWNED ROUTE FEATURES
              |
              v
DDR SPARSE ROUTER
  directory lookup
  bounded posting fetch
  candidate-ID generation
  dedup
  overflow telemetry
              |
              v
BOUNDED CANDIDATE DESCRIPTOR FETCH
  two independently-owned wave buffers
  WAVE=16
  MAX_OUT=2 after DDR gate PASS
              |
              v
PHYS=4 TERMGEN / SCORER
  base NodeRecord terms
  + query-derived terms
  + contextual learned delta
              |
              v
LOCAL STREAMING MIN-HEAP
  K=8
  no local sort on production path
  sift-on-take
  vector commit
              |
              v
GLOBAL STREAMING MIN-HEAP
  merge_done per wave
  ordered_valid final wave only
  one final sort
              |
              v
STRUCTURED TOP-8 / C9 EVIDENCE
              |
              v
native_ctx_bind
              |
              v
LM-06 (802,816 params)
              |
              v
FPGA TOKEN / RESPONSE
```

The legacy synthetic Gate14 candidate generator remains only as a simulation fixture/shadow reference until equivalence is proven. It must not remain as a second production retrieval engine in the final synthesis hierarchy.

# 7. Query Representation Authority

The host may provide only raw query/application tokens, command framing, and reward after an accepted learning transaction.

The host must not provide:

```text
entity anchor
intent class
relation class
context tag
hash
shard
bucket
candidate list
winner
episode address
relation path
next token
final answer
```

Native V1 uses a:

```text
DETERMINISTIC FPGA-NATIVE QUERY FEATURE EXTRACTOR
```

for Gate14 closure. It is not required to be a learned encoder.

The exact feature/mix law must be frozen by `QUERY-REPRESENTATION-AUTHORITY-00` before sparse-router implementation.

Required:

```text
same input query -> same route feature packet
small intended token changes -> measurable route-feature changes
no host semantic side-channel
all route keys derived in FPGA
feature packet observable in XSim
feature packet stable through request acceptance
```

A learned query encoder remains future work unless separately proven.

# 8. Sparse router architecture

## 8.1 Router law

```text
router = admission / locality authority
scorer + learned delta + Top-K = semantic ranking authority
```

## 8.2 Router profile must be evidence-selected

Initial design candidate:

```text
4 routing tables
compact route keys
bounded posting heads
DDR-backed posting storage
small BRAM directory cache
```

Before implementation run `SPARSE-ROUTER-RIVAL-AUDIT-00`.

Compare bounded profiles such as:

```text
2 tables × deeper postings
4 tables × moderate postings
8 small tables × shallow postings
hierarchical shard + bounded hash
```

Measure:

```text
held-out retrieval recall
overflow rate
duplicate rate
DDR bytes/query
candidates/query
bucket occupancy/skew
BRAM/LUT cost
timing estimate
```

Freeze `ROUTER_PROFILE_FINAL` only after evidence.

## 8.3 Candidate budget is parameterized

Do not hard-code `64` as Gate14 law before retrieval-quality evidence.

Run candidate-cap sweep:

```text
64
128
256
512
1024
```

Measure recall, Top-K preservation, overflow, duplicates, bytes/query, latency/query, and resource usage.

Then preregister:

```text
CAND_CAP_FINAL
DDR_QUERY_BOUND_FINAL
```

Hard law:

```text
candidates/query bounded independently of N
DDR bytes/query bounded independently of N
```

## 8.4 Canonical identities

All global episode/node identities must support at least the 800k address range. Do not depend on 16-bit global identity.

## 8.5 Overflow

Overflow must be bounded, counted, observable, and never silently hidden.

The system may claim bounded sparse retrieval, not exact global nearest-neighbor over arbitrary overflowed entries.

# 9. DDR wave engine

The first promoted memory implementation is:

```text
two wave buffers
+
MAX_OUT=2
+
explicit ownership
+
same AXI RID for overlapping wave requests
```

Distinct-RID wave fetches require a separate RID→bank demux/reorder gate and are not part of the first ping-pong implementation.

Each request is logically associated with:

```text
query_id
wave_id
buffer_id
expected_beats
generation/epoch
base address
```

Bank law:

```text
EMPTY
→ RESERVED
→ FILLING
→ READY
→ CONSUMED
→ EMPTY
```

Forbidden:

```text
consumer reads FILLING bank
producer overwrites READY bank
bank reused before consumer retirement
wave accepted twice
out-of-order wave delivery
```

`DDR-WAVE-PINGPONG-00` PASS requires:

```text
AR(N+1) < LAST_R(N) for recurring waves
outstanding high-water >= 2
II_STEADY < 46
AXI protocol errors = 0
drop/dup/overwrite/deadlock = 0
exact candidate sequence
exact Top-K
exact C9/OUT
```

Keep initially:

```text
WAVE = 16
PHYS = 4
R FIFO depth = 4
burst = 16
```

# 10. Top-K production architecture

```text
K                         = 8
PHYS                      = 4
WAVE                      = 16

LOCAL SORT_BEFORE_DRAIN   = 0
LOCAL SIFT_ON_TAKE        = 1
LOCAL VECTOR_COMMIT       = 1

GLOBAL SORT_EVERY_WAVE    = 0
GLOBAL merge_done         = one per wave
GLOBAL ordered_valid      = final wave only
GLOBAL final sort         = one
```

Serial Top-K remains simulation/differential oracle only.

Required:

```text
SET(minheap)   == SET(reference)
ORDER(final)   == ORDER(reference)
tie law        == frozen comparator law
drop           == 0
dup            == 0
```

# 11. Contextual learning and persistence

The bounded learned store becomes a hot learned-delta cache backed by persistent DDR state.

```text
host reward only
      |
      v
FPGA pending transaction
  selected node/edge/context
      |
      v
contextual delta law
      |
      v
hot learned-delta cache
      |
      +--> scorer hit/bypass
      |
      +--> bounded DDR write-back
```

Recommended semantic key:

```text
{subject_id, relation_id, object_id, context_tag, generation}
```

Required:

```text
host never sends winner/address
only accepted pending txn may update state
freeze rejects updates
held-out query changes due to learned delta
reset changes generation
old generation becomes invisible
flush/reload restores semantic identity
one physical bank has at most one writer/cycle
```

# 12. Root-B reachability re-audit

As soon as final V1 introduces learned-cache allocation, dirty eviction, or DDR learned-delta write-back, run:

```text
ROOT-B-REACHABILITY-REAUDIT-00
```

Required invariant:

```text
SUCCESSFUL COMPLETION
<=>
INTENDED ARCHITECTURAL STATE TRANSITION COMMITTED
```

Test cache hit, miss allocation, dirty eviction, DDR write-back stall/completion, capacity/overflow, generation mismatch, and reset during pending activity.

No ack/persist_done/commit counter may advance for a state transition that was not architecturally committed.

# 13. LM evidence interface

The LM must consume data from the single final retrieval path.

Preferred packet:

```text
beat 0: Top-8 node IDs
beat 1: relation/path summary
beat 2: context/intent summary
beat 3: confidence/prior/valid summary
```

If V1 retains one-beat ID-only context because of resource constraints, relation/path/context must remain independently visible in C9 evidence and the final claim must be narrowed.

Required chain:

```text
raw query
→ FPGA query representation
→ sparse router
→ bounded candidates
→ learned scorer
→ final ordered Top-8
→ C9/ctx
→ exactly one start_fwd
→ LM-06 active compute
→ exactly one done/pred
→ FPGA output
```

# 14. AXI ownership architecture

All DDR clients pass through one explicit owner/arbiter:

```text
BOOT / IMAGE LOAD
QUERY INDEX / POSTING READ
CANDIDATE DESCRIPTOR READ
LEARNED DELTA WRITE-BACK
LM WEIGHT-TILE DMA
SNAPSHOT / PERSISTENCE
```

Required:

```text
accepted AXI transaction finishes under one owner
new owner cannot observe prior owner's partial state
owner grant stable until transaction-idle authority
no persistence starvation indefinitely
```

Archive per client:

```text
transaction count
byte count
wait cycles
worst grant latency
error count
```

# 15. Verification authority repair

Before final integration, `HARNESS-AUTHORITY-FIX-00` must enforce:

```text
any SOA_PATTERN_FAIL => FAIL
cell_fail must equal 0
AOS NodeRecord schema = one canonical schema
N=64 control         = 1024 B / 64 beats
merge_done           = wave-completion authority
ordered_valid        = final ordered-result authority
final valid may occur after running falls
intentional corruption must produce a real FAIL
```

Historical performance gates backed by independent evidence remain historical evidence, but all promoted production behavior must be replayed under the repaired canonical harness before final freeze.

# 16. Resource policy

Historical reference:

```text
LUT      ≈ 35,993
FF       ≈ 44,163
RAMB36   ≈ 104 + one RAMB18
DSP      = 19
WNS      = +0.708 ns
Slice    = 15,589 / 15,850
```

Primary risk:

```text
slice packing
control sets
high-fanout control/reset
routing congestion
```

Hard acceptance:

```text
DEVICE_FIT = PASS
WNS >= 0
TNS = 0
WHS >= 0
THS = 0
UNROUTED = 0
FAILED_ROUTE = 0
DRC ERROR/FATAL = 0
unconstrained critical paths = 0
```

Preferred engineering targets, not automatic Gate14 law:

```text
WNS >= +0.5 ns preferred
free slices >= 800 preferred
RAMB36-equivalent <= 115 preferred
LUT <= 40k preferred
FF <= 50k preferred
DSP <= 32 preferred
```

Margin recovery:

```text
collapse duplicate retrieval paths
remove unused legacy scorer/TopK/control
compact debug/snapshot structures
reduce unnecessary async reset/control sets
retain PHYS=4
do not spend recovered margin on more lanes
```

# 17. Performance policy

Optimize useful candidates/cycle, not lane utilization.

After DDR ping-pong, remeasure the roofline. Do not automatically run TermGen-II or Global-TAKE-SIFT.

Sparse retrieval will change memory traffic fundamentally; do not over-optimize the old full-scan workload before M10 architecture is frozen.

# 18. M10 / 800k acceptance

M10 is not amended away.

Required:

```text
TOTAL_DATASET >= 800,000-addressable records/episodes
FULL_SCAN = NO

all query-time route keys generated by FPGA

CANDIDATES_PER_QUERY <= CAND_CAP_FINAL
bounded independently of N

DDR_BYTES_PER_QUERY <= DDR_QUERY_BOUND_FINAL
bounded independently of N

no loop termination depends on total database size

high-address sentinel representing record 799,999
retrieved/addressed correctly

overflow telemetry explicit
dedup explicit

held-out retrieval quality meets preregistered threshold

host query-time hash/winner/address = 0
```

Scale ladder:

```text
256
4,096
16,384
65,536
262,144
800,000
```

At each N record candidates/query, DDR/index bytes/query, latency/query, overflow, duplicates, bucket occupancy, retrieval correctness/recall, Top-K, and high-address behavior.

Reject if candidate or DDR traffic grows approximately linearly with N.

# 19. Canonical gate DAG

```text
U0  CANONICAL-WORKTREE-FREEZE-00
    |
U1  HARNESS-AUTHORITY-FIX-00
    |
U2  OPTIMIZED-FULLCHIP-COFIT-00
    current 310-cycle lineage, no board
    |
U3  DDR-WAVE-PINGPONG-00
    dual-bank, same-RID first implementation, MAX_OUT=2
    |
U3R ROOFLINE-REMEASURE-05
    |
U3Q QUERY-REPRESENTATION-AUTHORITY-00
    |
U4A SPARSE-ROUTER-RIVAL-AUDIT-00
    freeze ROUTER_PROFILE_FINAL
    freeze CAND_CAP_FINAL
    freeze DDR_QUERY_BOUND_FINAL
    |
U4  MEM02-SPARSE-DIRECTORY-00
    |
U5  MEM02-SPARSE-800K-00
    |
U6  UNIFIED-RETRIEVAL-00
    |
U7A ROOT-B-REACHABILITY-REAUDIT-00
    |
U7  CONTEXTUAL-LEARN-PERSIST-00
    |
U8  UNIFIED-LM-CHAIN-00
    |
U8R REMOVE-SYNTHETIC-PRODUCTION-PATH-00
    |
U9  FINAL-SOURCE-FREEZE-00
    |
U9S FINAL-SYNTH-00
    |
U9I FINAL-IMPL-00
    |
U9P FINAL-PREPROGRAM-CLOSURE-00
    |
U10 FINAL-BOARD-GATE14-00
    |
FINAL-56-BOX-RECONCILIATION
    |
NATIVE_V1_MINI_AI_BOARD_PASS
```

Each gate owns one primary unknown and stops at first divergence.

# 20. Gate-specific acceptance summary

## U0
Clean product RTL; MIG churn quarantined; exact source/evidence manifests.

## U1
`SOA_PATTERN_FAIL=0`; `cell_fail=0`; intentional corruption fails; 1024 B/64 beats control exact.

## U2
Full-chip synth/route/timing/hold/CDC/DRC pass; no board program.

## U3
Dual-bank ownership safe; same-RID overlapping request contract; outstanding HW>=2; `II_STEADY<46`; exact semantics.

## U3Q
Raw tokens generate deterministic FPGA-owned route features; no host semantic-route input; no fixed benchmark query-ID shortcut in production path.

## U4A
At least two bounded router profiles compared; candidate-cap sweep measured; final router/cap/byte bound preregistered.

## U4/U5
800k range; sentinel works; bounded cands/bytes; no full scan; overflow/dedup explicit; quality threshold passes.

## U6
One production candidate stream/scorer/Top-K; synthetic cand_* path absent from production retrieval hierarchy; learned delta changes held-out Top-K; C9 preserved.

## U7A
Success iff state committed; no false ack/persist_done; no lost dirty eviction; no double commit.

## U7
Reward updates FPGA-selected tuple; freeze/reset/retrain/flush/reload laws hold; DDR write-back exact; no dual writer.

## U8
C9/ctx exact; one forward start/done; LM-06 active compute; FPGA output; host final-answer/next-token zero.

## U8R
One production retrieval engine; synthetic benchmark generator simulation-only; full regression still passes.

# 21. Final-source freeze

Only after M10, HS13, unified retrieval, contextual persistence, LM chain, and Root-B final architecture all pass.

Record:

```text
FINAL_SOURCE_COMMIT
git status
production RTL manifest
XDC SHA
MIG XCI/config SHA
IP config SHA
build script SHA
Vivado version
TOP
PART
PHYS
WAVE
K
ROUTER_PROFILE_FINAL
CAND_CAP_FINAL
DDR_QUERY_BOUND_FINAL
```

No dirty working tree.

# 22. Final regression

Re-run:

```text
Root A epoch / REBIRTH
persistence identity
reset/forget/retrain
teacher-off
host leakage
query representation
sparse routing
M10 800k
Top-K differential
C9
LM active chain
HOLD_A / UNREL / CONTRA / HOLD_B
DDR ownership
Root B ack/commit
drop / dup / overwrite / deadlock
```

Frozen semantic oracle:

```text
HOLD_A C9 = 8382238122802120

OUT:
HOLD_A = 653
UNREL  = 689
CONTRA = 237
HOLD_B = 60
```

Any divergence => stop at first divergence. No oracle retarget.

# 23. Final synthesis / implementation

```text
TOP  = arty_a7_ng_native_v1_ab_soc_top
PART = xc7a100tcsg324-1
SIM_FULL = 0
PHYS = 4 unless later evidence explicitly promotes another value
```

Final implementation requires:

```text
WNS >= 0
TNS = 0
WHS >= 0
THS = 0
UNROUTED_NETS = 0
FAILED_ROUTE_NETS = 0
DRC ERROR/FATAL = 0
DEVICE_FIT = PASS
CDC reviewed
unconstrained critical paths = 0
```

# 24. Final bit / preprogram closure

Record source/build/bit provenance and require final SHA unique from all historical bits.

Before programming:

```text
LAW_GAPS      = 0
XSIM_GAPS     = 0
MIG_GAPS      = 0
METRIC_GAPS   = 0
M10           = PASS
HS13          = PASS
ROOT_B_FINAL  = CLOSED
SYNTH         = PASS
IMPL          = PASS
TIMING        = PASS
HOLD          = PASS
CDC           = PASS
DRC           = PASS
ROUTE         = PASS
FAIL          = 0
```

Only then:

```text
READY_TO_PROGRAM = YES
```

# 25. Final physical program

```text
BOARD = Digilent Arty A7-100T
PART  = xc7a100tcsg324-1

JTAG:
210319BE776EA
xc7a100t_0

UART:
COM12
115200
```

Procedure:

1. arm UART;
2. record listen start;
3. verify JTAG;
4. verify final bit SHA;
5. program with scripted Vivado Hardware Manager/TCL;
6. program exactly once;
7. record DONE/SHA/timestamp.

# 26. Final blind board exam

Prove live:

```text
teacher=0
external_LLM=0
learn=0
freeze=1

host_semantic_cue=0
host_winner=0
host_episode_address=0
host_relation_path=0
host_next_token=0
host_weight_writes=0
```

Required oracle:

```text
HOLD_A C9 = 8382238122802120
HOLD_A OUT = 653
UNREL OUT  = 689
CONTRA OUT = 237
HOLD_B OUT = 60
```

Also prove:

```text
raw query enters FPGA frontend
route features generated in FPGA
bounded sparse candidates generated
no full scan
learned delta visible
C9 generated from unified path
LM starts once
FPGA output generated
```

# 27. Final 56-box reconciliation

Only if:

```text
LAW_GAPS    = 0
XSIM_GAPS   = 0
BOARD_GAPS  = 0
METRIC_GAPS = 0
FAIL        = 0
```

declare:

```text
GATE14_PASS = YES
BOARD_PASS  = YES
NATIVE_V1_MINI_AI_BOARD_PASS = YES
```

Otherwise `GATE14_PASS=NO`.

# 28. Explicit non-goals

```text
open-domain chat claim
dynamic arbitrary online corpus insertion
exact global nearest-neighbor under arbitrary router overflow
EAM-03E integration without its own proof
Q*
NGRC replacement
LM quantization
PHYS=8/16
MAX_OUT=8
full 01R BRAM router
extra PE replication before sparse routing/resource closure
```

# 29. Hard stops

Stop on:

```text
HARD_FALSIFIER
FIRST_DIVERGENCE
AUTHORITY_CONFLICT
QUERY_REPRESENTATION_LEAK
ROUTER_FULL_SCAN
RETRIEVAL_RECALL_FAIL
ROOT_B_FALSE_COMMIT
SYNTH_FAIL
TIMING_FAIL
HOLD_FAIL
CDC_FAIL
DRC_FAIL
ROUTE_FAIL
RESOURCE_FIT_FAIL
WRONG_JTAG
UART_UNAVAILABLE
PREPROGRAM_NOT_READY
BOARD_FIRST_DIVERGENCE
```

Do not weaken acceptance criteria. Do not retarget C9/OUT. Do not program intermediate bits.

# 30. Immediate next action

```text
NEXT = U0-CANONICAL-WORKTREE-FREEZE-00

EVIDENCE_HEAD =
216bdc5bca9489963619e9bac566df7a3fc3b40e

PRODUCTION_RTL_ANCHOR =
24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded

RTL_EDIT = NO
BIT      = NO
PROGRAM  = NO
COM12    = UNTOUCHED
```

U0 output:

```text
clean-source manifest
dirty/generated MIG quarantine list
frozen artifact hashes
exact source SHA manifest
integration branch plan
U1 prereg
```

Then execute the canonical DAG continuously until final silicon or a real hard blocker.

# 31. Final architecture principle

```text
TRUTH > PROGRESS
EVIDENCE > CLAIM
ONE UNKNOWN > PATCH TREADMILL
ONE PRODUCTION DATAPATH > PARALLEL DEMOS
BOUNDED RETRIEVAL > FULL SCAN
ARCHITECTURAL COMMIT > ACK LABEL
FINAL SILICON > SIMULATION
```

Native V1 is complete only when the same final hardware path demonstrates:

```text
raw query
→ FPGA-owned representation
→ bounded sparse retrieval from an 800k-addressable store
→ learned contextual scoring
→ exact retained Top-K
→ structured C9
→ LM-06 active compute
→ FPGA-generated output
```

with teacher off, forbidden host semantic contribution zero, persistent learned state, clean implementation, and one blind final board proof.
