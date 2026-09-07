# Grok Continuous Execution Prompt — Native AI Blueprint V3.1

**Purpose:** Force Grok to follow `UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md` continuously from U0 through final board closure, without stopping after normal PASS gates.

**Authority file:**  
`D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00\UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md`

---

```

```
LOCAL AUTHORITY:
D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00\UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md

BOARD:
Digilent Arty A7-100T

PART:
xc7a100tcsg324-1

VIVADO:
2026.1

JTAG:
210319BE776EA
xc7a100t_0

UART:
COM12 @ 115200

==================================================
0. ABSOLUTE AUTHORITY
==================================================

Đọc toàn bộ file:

D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00\UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md

và coi nó là:

MASTER ARCHITECTURE AUTHORITY
+
MASTER EXECUTION AUTHORITY
+
FINAL GATE DAG AUTHORITY

cho toàn bộ Native V1 từ thời điểm này tới final board closure.

Nếu:
- chat cũ,
- README cũ,
- LOOP_STATE cũ,
- branch status cũ,
- roadmap cũ,
- Grok note cũ,
- deprecated Gate14 document,
- optimization idea trước đây

xung đột với Blueprint V3.1:

BLUEPRINT V3.1 WINS.

Ngoại lệ duy nhất:
Nếu Blueprint V3.1 xung đột trực tiếp với unchanged Gate14 §14 acceptance contract
hoặc hard-stop authority hiện hành,
DỪNG và báo AUTHORITY_CONFLICT.
Không tự sửa luật.

Doctrine:

Master Blueprint defines architecture.
Evidence defines truth.
Status files describe execution only when current.
Chat memory is not project authority.

==================================================
1. CURRENT START STATE
==================================================

EVIDENCE_HEAD =
216bdc5bca9489963619e9bac566df7a3fc3b40e

PRODUCTION_RTL_ANCHOR =
24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded

Current optimized retrieval evidence:

PHYS = 4
WAVE = 16
K    = 8

T_QUERY = 310 cycles

Current promoted gates include:

CUE-OVERLAP-READY-00                  PASS
LOCAL-SORT-ELIDE-00                   PASS
HEAP-TAKE-SIFT-00                     PASS
LOCAL-TOPK-PARALLEL-COMMIT-00         PASS
GLOBAL-MERGE-DONE-SPLIT-00            PASS
GLOBAL-SORT-FINAL-ONLY-00             PASS
DDR-EXPOSED-REMEASURE-00              PASS

Current DDR evidence:

AR_TO_FIRST_R   = 24 cycles/wave
FETCH_SERVICE   = 44/42/42/42
II_STEADY       = 46
OUTSTANDING_HW  = 1
R_BACKPRESSURE  = 0
FIFO_HW         = 1
AR/query        = 4
beats/query     = 64
bytes/query     = 1024

Current status:

GATE14_PASS = NO
BOARD_PASS  = NO
PROGRAM     = NO
BIT         = NO
M10         = OPEN
HS13        = OPEN / current full-scan architecture unacceptable

==================================================
2. FROZEN SEMANTIC ORACLE
==================================================

Không được thay đổi hoặc retarget:

HOLD_A C9 =
8382238122802120

OUT:

HOLD_A = 653
UNREL  = 689
CONTRA = 237
HOLD_B = 60

Bất kỳ source change nào làm thay đổi frozen semantic oracle:

STOP.

Phải báo:

FIRST_DIVERGENCE
VIOLATED_INVARIANT
EVIDENCE_CLASS
AFFECTED_STAGE
SMALLEST_NEXT_EXPERIMENT

Không được sửa expected value để làm PASS.

==================================================
3. FROZEN BOARD BITS
==================================================

TUYỆT ĐỐI KHÔNG PROGRAM LẠI:

1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9

9CA2B30DCCD8A7AA2F348C3C4E2BDFCDAF9A9A67CBE0956EB0A8EBB532BADC80

F24150BDE6F69080B3C5865386C49F6F02300782FFB4037FAF044BB2099840F7

Không dùng GUI historical Write Bitstream.

Không program bất kỳ performance/intermediate candidate nào.

Bit kế tiếp được program phải là:

THE UNIQUE FINAL CLOSED CANDIDATE.

==================================================
4. CONTINUOUS EXECUTION
==================================================

CONTINUOUS_EXECUTION = ON
ASK_BEFORE_NEXT_GATE = NO
AUTO_ADVANCE_ON_PASS = YES

Sau mỗi gate PASS:

1. archive raw evidence
2. calculate SHA256
3. write PREREG.md
4. write RESULTS.md
5. write METRICS.json
6. write CLOSEOUT.md
7. commit exact promoted delta
8. record production files changed
9. update evidence ledger
10. immediately start the next authorized gate

Không hỏi:

"Should I continue?"
"Do you want me to proceed?"
"May I start the next gate?"

Standing authorization:

CONTINUE = YES

cho tới:
- final completion
hoặc
- một HARD BLOCKER thật.

==================================================
5. ONE-UNKNOWN RULE
==================================================

Mỗi RTL gate chỉ được có:

ONE PRIMARY UNKNOWN.

Flow bắt buộc:

UNKNOWN
→ prereg
→ smallest delta
→ unit/differential test
→ full relevant regression
→ measurement
→ PASS / FAIL / INCONCLUSIVE
→ next gate

Không gom nhiều architecture changes độc lập vào một gate.

Không refactor rộng chỉ vì code xấu.

Không cleanup ngoài causal path trong cùng experiment.

==================================================
6. CANONICAL DAG — EXECUTE IN THIS ORDER
==================================================

Bắt đầu ngay từ:

U0-CANONICAL-WORKTREE-FREEZE-00

Sau đó:

U0  CANONICAL-WORKTREE-FREEZE-00
    |
U1  HARNESS-AUTHORITY-FIX-00
    |
U2  OPTIMIZED-FULLCHIP-COFIT-00
    |
U3  DDR-WAVE-PINGPONG-00
    |
U3R ROOFLINE-REMEASURE-05
    |
U3Q QUERY-REPRESENTATION-AUTHORITY-00
    |
U4A SPARSE-ROUTER-RIVAL-AUDIT-00
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

Không tự reorder DAG nếu Blueprint không cho phép.

Nếu measurement mở một sub-gate causal bắt buộc,
sub-gate đó phải:
- prereg riêng,
- one unknown,
- không làm thay đổi final architecture law,
- quay lại canonical DAG sau khi đóng.

==================================================
7. U0 — CANONICAL WORKTREE FREEZE
==================================================

Bắt đầu ngay.

U0:

RTL_EDIT = NO
BIT      = NO
PROGRAM  = NO

Phải:

- xác nhận exact branch/head
- ghi EVIDENCE_HEAD
- ghi PRODUCTION_RTL_ANCHOR
- tạo clean source manifest
- quarantine generated MIG dirtiness
- không commit generated MIG churn
- phân biệt intentional IP/XCI change với generated cache
- archive frozen board hashes
- archive current production RTL SHA
- đảm bảo không cross-write giữa worktrees
- tạo integration branch sạch theo Blueprint
- chuẩn bị prereg U1

U0 PASS chỉ khi product lineage sạch và traceable.

==================================================
8. U1 — HARNESS AUTHORITY FIX
==================================================

Legacy harness không được phép:

SOA_PATTERN_FAIL
cell_fail=1
P3P4_REPAIR_TB_PASS

cùng tồn tại.

Canonical law:

any SOA_PATTERN_FAIL => FAIL

cell_fail must equal 0

N=64 AOS transport:
1024 bytes
64 beats

merge_done =
wave completion authority

ordered_valid =
final ordered result authority

final ordered_valid có thể đến sau running=0.

Intentional corruption phải tạo FAIL thật.

Sau U1:
replay các promoted performance regressions cần thiết dưới canonical harness.

Không phủ nhận historical evidence,
nhưng final source freeze không được dựa trên contradictory legacy harness.

==================================================
9. U2 — FULLCHIP COFIT
==================================================

Run full:

SYNTH
IMPLEMENTATION
TIMING
HOLD
CDC
DRC
ROUTE
RESOURCE

cho current 310-cycle lineage.

NO PROGRAM.
NO FINAL BIT CLAIM.

Archive:

hierarchical utilization
control sets
high fanout
BRAM
DSP
LUT
FF
slice usage
clock interaction
timing summary
route status
DRC
CDC

Hard:

WNS >= 0
TNS = 0
WHS >= 0
THS = 0
route clean
DRC clean
fit PASS

Preferred margin không được biến thành hard FAIL nếu Blueprint không nói vậy.

==================================================
10. U3 — DDR WAVE PING-PONG
==================================================

Primary unknown:

Can dual-bank, MAX_OUT=2 memory-level parallelism hide recurring DDR RTT
without semantic or ownership corruption?

First implementation:

2 wave buffers
MAX_OUT = 2
same AXI RID for overlapping wave requests

Do NOT use distinct RID unless mở gate RID→bank demux riêng.

Structural PASS:

AR(N+1) < LAST_R(N)

outstanding high-water >= 2

II_STEADY < 46

Keep:

WAVE=16
PHYS=4
burst=16
R FIFO depth=4

Bank ownership law:

EMPTY
→ RESERVED
→ FILLING
→ READY
→ CONSUMED
→ EMPTY

Must prove:

drop=0
dup=0
overwrite=0
deadlock=0
out_of_order_delivery=0
RRESP=0
RLAST=0
RID_ORDER=0

Exact candidate stream / TopK / C9 / OUT preserved.

==================================================
11. U3R — ROOFLINE
==================================================

Remeasure:

C_D
C_T
C_L
C_G
II_STEADY
TAIL_LATENCY
cand/cycle
DDR service
DDR exposed wait
R occupancy
outstanding high-water

Do not auto-open old microoptimization gates.

Do not optimize full-scan path indefinitely.

Sparse retrieval is the next architecture objective.

==================================================
12. U3Q — QUERY REPRESENTATION AUTHORITY
==================================================

This gate is mandatory.

Raw query must become route features inside FPGA.

Native V1 uses:

DETERMINISTIC FPGA-NATIVE QUERY FEATURE EXTRACTOR

unless a separately proven learned encoder is explicitly authorized.

Host may provide:

raw query/application tokens
framing
reward

Host may NOT provide:

entity
intent
relation
context
hash
bucket
shard
candidate ID
winner
address
relation path
next token
final answer

Prove:

raw query
→ FPGA feature packet
→ FPGA route keys

No fixed benchmark query-ID shortcut in final production path.

==================================================
13. U4A — ROUTER RIVAL AUDIT
==================================================

Do NOT assume:

4 tables
16-bit keys
candidate cap 64

are final architecture truths.

Compare bounded profiles.

At minimum compare two meaningful alternatives.

Candidate-cap sweep should include appropriate values such as:

64
128
256
512
1024

Measure:

held-out recall
TopK preservation
overflow
duplicates
bucket skew
candidates/query
DDR bytes/query
latency
BRAM/LUT
timing risk

Then freeze:

ROUTER_PROFILE_FINAL
CAND_CAP_FINAL
DDR_QUERY_BOUND_FINAL
RETRIEVAL_QUALITY_THRESHOLD_FINAL

Only after evidence.

==================================================
14. U4/U5 — M10 SPARSE 800K
==================================================

800k remains mandatory.

800k means:

persistent addressable episode corpus

NOT:

score 800k episodes every query.

Required:

TOTAL_DATASET >= 800000 addressable records

FULL_SCAN = NO

query-time route keys FPGA-derived

candidates/query <= CAND_CAP_FINAL

DDR bytes/query <= DDR_QUERY_BOUND_FINAL

both bounded independently of N

no loop termination dependent on database size

record 799999 high-address sentinel must work

overflow telemetry explicit

dedup explicit

retrieval quality >= preregistered threshold

host hash/winner/address = 0

Scale ladder:

256
4096
16384
65536
262144
800000

Measure every scale.

Reject architecture if:

candidates/query ∝ N

or

DDR bytes/query ∝ N

==================================================
15. U6 — UNIFIED RETRIEVAL
==================================================

This is a major final architecture gate.

Final production chain must become:

raw query
→ FPGA representation
→ sparse candidate IDs
→ candidate descriptors
→ learned scorer
→ Local Minheap
→ Global Minheap
→ C9
→ LM

The synthetic Gate14 candidate generator must no longer be a production retrieval engine.

Keep it only as:

simulation shadow oracle
regression fixture

until final equivalence.

Production must have:

one candidate stream
one scorer authority
one Local/Global TopK path
one C9 path
one LM path

No duplicate demo pipelines.

==================================================
16. U7A — ROOT B REACHABILITY
==================================================

When learned DDR write-back becomes real,
old Root-B closure cannot be inherited automatically.

Reopen transaction semantics.

Required invariant:

SUCCESSFUL COMPLETION
<=>
INTENDED ARCHITECTURAL STATE TRANSITION ACTUALLY COMMITTED

Test:

cache hit
cache miss allocation
dirty eviction
DDR write stall
DDR write completion
capacity condition
generation mismatch
reset during pending transaction

No false ack.
No false persist_done.
No lost dirty state.
No double commit.

==================================================
17. U7 — CONTEXTUAL LEARN / PERSIST
==================================================

Native V1 scope:

preloaded static corpus up to 800k
+
online contextual learned deltas

NOT dynamic arbitrary online corpus insertion.

Learning flow:

host reward only
→ FPGA-selected pending tuple
→ contextual delta
→ hot learned-delta cache
→ scorer effect
→ DDR write-back

Host does not provide winner or address.

Prove:

learned delta changes held-out TopK/evidence
freeze rejects update
reset/retrain works
generation works
flush/reload restores semantic identity
cache conservation exact
DDR persistence exact

==================================================
18. U8 — UNIFIED LM CHAIN
==================================================

Prove:

real unified sparse C9
→ ctx
→ exactly one start_fwd
→ LM-06 active
→ exactly one done
→ pred
→ FPGA response

Keep:

P_LM = 802,816

Host:

final answer = 0
next token = 0
weight write during final teacher-off = 0

Frozen OUT remains:

653 / 689 / 237 / 60

==================================================
19. U8R — REMOVE SYNTHETIC PRODUCTION PATH
==================================================

Only after unified path equivalence is proven:

remove synthetic Gate14 candidate path from final production synthesis hierarchy.

Keep reference version in:

simulation / differential tests only.

Then rerun full causal regression.

==================================================
20. FINAL SOURCE FREEZE
==================================================

Only after:

M10=PASS
HS13=PASS
query representation=PASS
unified retrieval=PASS
Root B final=PASS
contextual persistence=PASS
LM chain=PASS

Create unique:

FINAL_SOURCE_COMMIT

Record:

git status
RTL manifest
TOP
PART
PHYS
WAVE
K
XDC SHA
MIG XCI/config SHA
IP config SHA
build script SHA
Vivado version
ROUTER_PROFILE_FINAL
CAND_CAP_FINAL
DDR_QUERY_BOUND_FINAL

Dirty tree = STOP.

==================================================
21. FINAL REGRESSION
==================================================

Re-run all required:

Root A
REBIRTH
persistence
reset/retrain
teacher-off
host leakage
query representation
sparse routing
M10 800k
TopK differential
C9
LM
DDR ownership
Root B
drop/dup/overwrite/deadlock

Frozen oracle unchanged.

Any divergence:

STOP AT FIRST DIVERGENCE.

==================================================
22. FINAL SYNTH / IMPLEMENTATION
==================================================

TOP:
arty_a7_ng_native_v1_ab_soc_top

PART:
xc7a100tcsg324-1

PHYS:
4 unless separately promoted by evidence

Required implementation:

WNS >= 0
TNS = 0
WHS >= 0
THS = 0
UNROUTED = 0
FAILED_ROUTE = 0
DRC ERROR/FATAL = 0
DEVICE_FIT = PASS
CDC reviewed
unconstrained critical paths = 0

No historical GUI Write Bitstream.

==================================================
23. PREPROGRAM HARD GATE
==================================================

Only if:

LAW_GAPS      = 0
XSIM_GAPS     = 0
MIG_GAPS      = 0
METRIC_GAPS   = 0
FAIL          = 0

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

then:

READY_TO_PROGRAM = YES

otherwise:

PROGRAM = NO

==================================================
24. FINAL PROGRAM
==================================================

When READY_TO_PROGRAM=YES only:

1. arm COM12 @115200 first
2. record LISTEN_START
3. verify JTAG exactly:
   210319BE776EA
   xc7a100t_0
4. verify unique final bit SHA
5. scripted Vivado Hardware Manager/TCL only
6. program exactly once
7. record PROGRAM_ATTEMPT=1
8. archive DONE/timestamp/SHA

Do not reprogram the same final bit after successful configuration.

==================================================
25. FINAL BLIND BOARD EXAM
==================================================

On the same bit prove:

teacher=0
external_LLM=0
learn=0
freeze=1

host semantic/query shortcuts = 0
host winner = 0
host episode address = 0
host relation path = 0
host next token = 0
host weight writes = 0

Frozen:

HOLD_A C9 = 8382238122802120

OUT:
653
689
237
60

Also prove:

raw query
→ FPGA representation
→ sparse candidate generation
→ no full scan
→ learned contextual effect
→ unified C9
→ LM start
→ FPGA output

Archive raw UART + SHA.

No second programming to rescue a failed blind exam.

==================================================
26. FINAL RECONCILIATION
==================================================

Run all 56 Gate14 boxes.

For every box record:

status
evidence class
artifact
source commit
bit SHA if applicable
reason

Final rollup:

LAW_GAPS
XSIM_GAPS
BOARD_GAPS
METRIC_GAPS
FAIL

Only if:

LAW_GAPS    = 0
XSIM_GAPS   = 0
BOARD_GAPS  = 0
METRIC_GAPS = 0
FAIL        = 0

may you report:

GATE14_PASS = YES
BOARD_PASS = YES
NATIVE_V1_MINI_AI_BOARD_PASS = YES

Otherwise:

GATE14_PASS = NO

==================================================
27. HARD STOP CONDITIONS
==================================================

Only stop continuous execution for:

HARD_FALSIFIER
FIRST_DIVERGENCE
AUTHORITY_CONFLICT
QUERY_REPRESENTATION_LEAK
ROUTER_FULL_SCAN
RETRIEVAL_QUALITY_FAIL
ROOT_B_FALSE_COMMIT
SYNTH_FAIL
TIMING_FAIL
HOLD_FAIL
CDC_FAIL
DRC_FAIL
ROUTE_FAIL
RESOURCE_FIT_FAIL
NO_HARDWARE
WRONG_JTAG
UART_UNAVAILABLE
PREPROGRAM_NOT_READY
BOARD_FIRST_DIVERGENCE

When stopping, do NOT ask a vague question.

Return exactly:

BLOCKER
FIRST_DIVERGENCE
VIOLATED_INVARIANT
EVIDENCE_CLASS
AFFECTED_COMMIT
AFFECTED_ARTIFACT
WHY CONTINUATION IS UNSAFE
SMALLEST_NEXT_EXPERIMENT
PROGRAM_STATE

Do not weaken acceptance criteria.

==================================================
28. EXECUTION OUTPUT FOR EVERY GATE
==================================================

Canonical evidence path:

results/A7-NATIVE-GRAPH/GROK-ORCH-00/<GATE>/

Every gate must create:

PREREG.md
LOCK.txt
RESULTS.md
METRICS.json
CLOSEOUT.md
raw logs
SHA256 manifest

Every CLOSEOUT states:

GATE
BASE
SOURCE_COMMIT
RTL_EDIT
FILES_CHANGED
BIT_BUILD
PROGRAM
GATE14_PASS
M10
PRIMARY_UNKNOWN
RESULT
EVIDENCE_CLASS
FIRST_DIVERGENCE
FALSIFIED_ALTERNATIVES
NEXT

==================================================
29. CONTINUOUS FINAL DIRECTIVE
==================================================

BEGIN NOW:

U0-CANONICAL-WORKTREE-FREEZE-00

Then continue automatically according to:

UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md

until either:

A.
NATIVE_V1_MINI_AI_BOARD_PASS = YES

or

B.
a real hard blocker is reached.

Do not stop after a normal PASS.

Do not ask permission to continue.

Do not program intermediate bits.

Do not substitute speed for evidence.

Do not change the oracle.

Do not silently change the architecture.

Do not silently amend M10.

Do not hide FAIL behind PASS text.

TRUTH > PROGRESS
EVIDENCE > CLAIM
ONE UNKNOWN > PATCH TREADMILL
ONE PRODUCTION DATAPATH > PARALLEL DEMOS
BOUNDED RETRIEVAL > FULL SCAN
ARCHITECTURAL COMMIT > ACK LABEL
FINAL SILICON > SIMULATION

START U0 NOW.
