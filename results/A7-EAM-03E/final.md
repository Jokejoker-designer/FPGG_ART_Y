YOU ARE NOW THE PRIMARY ENGINEERING AGENT FOR CLOSING NATIVE AI V1
ON DIGILENT ARTY A7-100T BEFORE ANY GLASSBOX WORK BEGINS.

Repository:
D:\Jetking_sem4\SEM_4\arty-a7-online-lm

Vivado:
C:\2026.1\Vivado

Board:
Digilent Arty A7-100T
xc7a100tcsg324-1
Device serial: 210319BE776EA
UART baseline: COM12 @ 115200

IMPORTANT:
Do not assume the board is currently connected.
Detect/report availability before any silicon step.

====================================================================
0. PRIMARY OBJECTIVE
====================================================================

Close a scientifically defensible Native AI V1 that performs this complete
post-bitstream chain:

USER/TASK DATA
    ↓
FPGA representation encoder
    ↓
FPGA-native learning
    ↓
learned reusable cue
    ↓
FPGA episodic retrieval
    ↓
mutable learned episode / knowledge
    ↓
802,816-parameter FPGA Transformer/controller
    ↓
FPGA next-token/output path
    ↓
teacher-off evaluation

The final system must behave as a SMALL, NARROW-DOMAIN AI MODEL.

It does NOT need to be:
- an open-domain chatbot;
- an LLM;
- ChatGPT-like;
- a general semantic model.

The intended V1 demonstration is narrow-domain English fact learning,
retrieval and response generation after bitstream load.

GlassBox / ILA / LiteScope / UI instrumentation is explicitly OUT OF SCOPE
until Native AI V1 is frozen.

Do not add GlassBox logic while trying to close the model.
At the end, only prepare a trace-point handoff for the future GlassBox phase.

====================================================================
1. AUTHORITY ORDER
====================================================================

Before editing RTL, read and reconcile at least:

1. results/A7-EAM-03E/BAN_GIAO_2026-08-19.md
2. HANDOFF.md
3. docs/contracts/A7-EAM-02M.md
4. docs/contracts/A7-EAM-03E.md
5. docs/contracts/A7-EAM-03E-A.md
6. docs/contracts/A7-EAM-03E-A01.md
7. docs/contracts/A7-EAM-03E-A02.md
8. docs/architecture/LINEAGE.md
9. rtl/eam/eam03e_core.sv
10. results/A7-EAM-03E/a01t_eupd/eam03e_core.sv
11. KIDI_TRAINING_LESSON_PLAN.md
12. A7-LM-06 closeout / contract / lessons
13. frozen 01R and 02M closeouts.

If repository state conflicts with this prompt:
- stop;
- identify the exact conflict;
- show file/line/artifact evidence;
- do not silently choose one.

Latest scientific override:
A7-SIM-BENCH has shown that the current 03E learning dynamics can improve
initially and then collapse after longer training due recurrent scale runaway:
Wh/acc grows, h saturates, effective rank collapses, distances degenerate,
AUC tends toward 0.5.

Therefore:
M_L1 alone is NOT an adequate authority.
A good-looking margin produced by representation collapse is a FAIL.

====================================================================
2. SCIENTIFIC LAW
====================================================================

Always enforce:

FITS != RUNS != TRAINS != CONVERGES != USEFUL

Classify results honestly:

EVIDENCE
ENGINEERING_INFERENCE
NEEDS_EXPERIMENT
FALSE_OR_OVERCLAIM

Never promote a milestone because one easy test passes.

BOARD_PASS requires:
- correct RTL/function;
- implementation timing closure;
- silicon evidence;
- frozen artifact hashes;
- required scientific/learning gates.

====================================================================
3. HARDWARE LEARNING BOUNDARY
====================================================================

Host/CPU MAY:
- tokenize UTF-8 / token IDs;
- load datasets;
- provide teacher labels/reward during TRAIN;
- log results;
- calculate evaluation-only metrics such as cosine from raw FPGA telemetry;
- save artifacts.

Host/CPU MUST NOT:
- calculate FPGA gradients;
- calculate weight deltas;
- send trained weights as per-example updates;
- choose EAM winner;
- choose internal way;
- choose BRAM/DDR record address;
- generate the 64-bit learned cue;
- compute FPGA next token in the release proof;
- hardcode prompt→response mappings.

Teacher is TRAIN-only supervision.

Teacher may provide:
- text/tokens;
- anchor/positive/negative relation;
- SAME/DIFF;
- scalar reward;
- curriculum/task labels;
- target answer data.

Teacher must NOT provide:
- gradient;
- weight delta;
- internal hash;
- winning address;
- memory location;
- precomputed similarity winner.

Final proof:

teacher = 0
external_LLM = 0
learn = 0
freeze = 1

FPGA must perform forward/retrieval/output itself.

====================================================================
4. FROZEN ARTIFACT LAW
====================================================================

DO NOT overwrite or silently rebuild frozen artifacts:

A7-EAM-01R
A7-EAM-02M
A7-LM-00 ... A7-LM-06

In particular preserve the known frozen bitstream artifacts and SHA hashes.

A final integrated design MAY instantiate frozen RTL semantics under a NEW
top-level milestone and produce a NEW bitstream.

That is allowed.

But:
- do not replace the frozen historical bit;
- do not call a rebuilt integration bit "the same frozen LM-06 bit";
- verify the integrated LM behavior against the frozen LM-06 oracle.

Every new milestone gets:
- new ID;
- new output directory;
- new bit filename;
- SHA256;
- timing reports;
- source snapshot;
- host/test scripts;
- closeout.

====================================================================
5. CURRENT LOCKED STATE
====================================================================

Treat this as baseline until independently verified.

A7-EAM-01R:
FROZEN / BOARD_PASS

A7-EAM-02M:
FROZEN / BOARD_PASS

A7-LM-06:
FROZEN / BOARD_PASS
P_LM = 802,816

A7-EAM-03E-A0:
XSIM_PASS
SILICON_FUNCTIONAL_PASS_WITH_NOTES
TIMING_FAIL
SEED_ROBUSTNESS_FAIL
A1 CLOSED

A0.1-T:
timing-only lineage
learning law must remain eam03e-a0-signsgd-v1
latest archived implementation:
WNS = -0.119 ns
TNS = -0.407 ns
DSP = 0
not BOARD_PASS

Live RTL has S_DIST → S_DADD timing patch.
This live patch still needs authoritative regression and implementation proof.

Golden authority:

seed = 0x11111111
32 steps

initial:
AB = 3930
AC = 5362

after BETA=SAME:
AB = 1093
AC = 2012

RESEED:
AB = 3930

after OMEGA=SAME:
AC = 451
AB = 1574

Do not substitute the old STEPS=24 silicon values.

Known bad seed:
0x22222222

SAME:
2135 → 1487

DIFF:
1679 → 229

M_L1 = 229 - 1487 = -1258

This is a current FAIL of discriminative robustness.

====================================================================
6. EXECUTION RULE
====================================================================

Work milestone by milestone.

At each milestone:

1. inspect;
2. make the smallest justified change;
3. run regression;
4. run scientific gate;
5. run implementation if required;
6. archive results;
7. produce PASS/FAIL;
8. only then move on.

Never solve two unknowns in one patch unless physically unavoidable.

If a gate FAILS:
STOP THAT BRANCH.
Diagnose it.
Do not continue downstream to hide the failure.

====================================================================
7. PHASE T — CLOSE A0.1-T FIRST
====================================================================

Objective:
Close timing WITHOUT changing numerical law.

Step T1:
Run:

tests/xsim/run_a7eam03e.tcl

on current live RTL containing S_DADD.

Required exact golden:

3930 / 5362
→
1093 / 2012
→
3930
→
451 / 1574

All integer authority values must remain exact.

If any changes:
FAIL = TIMING PATCH REGRESSION.

Compare current RTL against:
results/A7-EAM-03E/a01t_eupd/eam03e_core.sv

Find the first arithmetic/order change.

Do NOT update the golden.

Step T2:
Run full implementation:

vivado/tcl/build_a7eam03e.tcl

Hard gate:

WNS >= 0
TNS = 0
DSP = 0

If WNS remains negative:
continue pipeline partitioning of the timing path only.

Do not:
- change learning law;
- change d1;
- alter E3_MARG;
- alter tokenizer;
- move into triplet training to escape timing.

Step T3:
Archive the successful bit BEFORE touching build/out.

Create a dedicated result directory.

Record:
- bit SHA256;
- source SHA256;
- WNS;
- TNS;
- WHS;
- LUT;
- FF;
- BRAM;
- DSP;
- exact XSim golden.

Step T4:
When board is available:
program only the new T candidate.
Use STEPS=32.
Run silicon golden.

Required:
board values == XSim values.

Only after:
XSim exact
AND WNS>=0
AND TNS=0
AND DSP=0
AND silicon exact

may A0.1-T be called BOARD_PASS.

====================================================================
8. PHASE S — LONG-HORIZON STABILITY BEFORE REPULSION
====================================================================

This phase is mandatory due the newer SIM benchmark finding.

Do NOT immediately add stronger negative push before proving that recurrent
state does not run away.

First reproduce baseline collapse with the current law.

Use UPDATE COUNT as horizontal axis, not epochs alone.

Suggested locked checkpoints:

0
32
64
128
256
512
1000
2000
5000
10000 updates

At each checkpoint record at minimum:

AUC
AP
M_L1
M_cos
effective_rank
unique_d1_count
positive_distance distribution
negative_distance distribution
max_abs_h
fraction_h_clipped
max_abs_acc
fraction_acc_clipped
||Wh||1
max_abs_Wh
embedding rail count
weight update count

Do not trust M_L1 if effective_rank collapses.

First establish untrained baseline.

Then establish current-law baseline.

Only after reproducing the failure should the smallest stability patch be made.

Allowed stability experiments, ONE AT A TIME:

S1:
reduce recurrent Wh update magnitude / rate

S2:
hard or symmetric bound on Wh

S3:
mild Wh decay, only if S1/S2 are insufficient

Do not simultaneously:
- change tokenizer;
- change encoder architecture;
- add cosine training;
- add 01R;
- add 02M;
- add LM-06.

Primary stability gate:

AUC_post > AUC_init

AND

AUC must not return to approximately 0.5 over the intended horizon

AND

effective_rank must remain noncollapsed

AND

hidden saturation must stay far below total collapse

AND

unique_d1_count > 1

AND

Wh/acc telemetry must not show uncontrolled runaway.

If 10,000-update evaluation is too slow for RTL simulation,
use a validated bit-identical host/reference twin for the long sweep
and confirm selected checkpoints in XSim.

Document exactly which evidence is:
XSim
reference model
board.

Do not mix them.

====================================================================
9. PHASE A0.2-L — DISCRIMINATIVE LEARNING
====================================================================

Only begin after stability has been demonstrated.

Implement new versioned law.
Do not modify A0.1-T contract.

Required training transaction:

(A, P, N)

one atomic training command.

Preferred UART command per existing contract:
0x25

Do NOT implement this as:
PAIR(A,P,SAME)
then
PAIR(A,N,DIFF)

The TRAIN authority remains L1.

Triplet hinge:

L = max(0, d(A,P) - d(A,N) + margin)

Definitions:

M_L1 =
d(A,N) - d(A,P)

M_cos =
cos(A,P) - cos(A,N)

Cosine is EVAL TELEMETRY ONLY in L1.

Do NOT use cosine to train unless a later separately versioned experiment
explicitly justifies it.

Telemetry on PAIR/TRIPLET should include enough raw values for host-side
evaluation:

d1
dH
n1
max_abs
mean_abs
dot
n2sq

The host may calculate cosine for evaluation.

Hard anti-overtraining behavior:
if the margin objective is already satisfied,
the transaction should not continue modifying weights unnecessarily.

Do not silently tune margin to pass a failing seed.

Required bad-seed test includes:
0x22222222

Minimum non-inversion hard stop:
M_L1 >= 0 on 0x22222222

Full closure should require on the pre-registered confirmation set:
M_L1 > 0
AND
M_cos > 0
AND
no representation collapse
AND
no seed inversion.

Run multiple independent seeds.
Pre-register the seed set before tuning.

Do not select only successful seeds after the fact.

====================================================================
10. A7-SIM-BENCH AUTHORITY
====================================================================

Use the real held-out benchmark rather than only the 3-string golden.

The 3-string golden is a regression test.
It is NOT a representation-quality benchmark.

Dataset splitting:
split by ENTITY / connected component where relation is transitive.

Do not pair-split the same entities across TRAIN and EVAL.

Metrics:
tie-aware AUC
uninterpolated AP
effective rank
saturation
distance overlap
M_L1
M_cos

Always include:
UNTRAINED ENCODER baseline

and classical string-distance baselines where the benchmark supports them.

Do not claim semantic paraphrase if the dataset/task is only short-string
record linkage.

If classical string metrics beat the learned encoder,
report it.

The research value may still be online post-bitstream adaptation,
not static metric superiority.

====================================================================
11. PHASE A1 — GLUE 03E TO FROZEN 01R/02M
====================================================================

A1 remains CLOSED until all previous gates pass.

A1 purpose:

UTF-8
→
03E learned encoder
→
64-bit cue
→
01R candidate router
→
02M episode binding/retrieval

Do not change frozen 01R thresholds to compensate for encoder weakness.

Do not retune:
HIT_MAX
MARGIN_MIN
or frozen router law
based on A1 failures.

Host must not send:
cue
winner
way
address
precomputed match.

Required A1 proof:

1. exact learned cue retrieval;
2. known d<=8 perturbation behavior where applicable;
3. learned related cue reaches intended episode;
4. unrelated cue rejects;
5. teacher-off probe works;
6. reset/retrain works;
7. host did not choose internal winner.

Most important:
an UNSEEN evaluation formulation must succeed because of the learned
representation, not because it was explicitly bound before evaluation.

If all successful test queries were seen during binding:
that is exact/multi-cue memory only,
NOT generalization.

====================================================================
12. PHASE KIDI — 20–40 ENGLISH FACTS
====================================================================

This is the first system-level AI behavior milestone.

Use a small, frozen English fact task.

Start with approximately 20 facts.
Then 40 facts.

Facts must be introduced AFTER bitstream programming.

Teacher may be used only during TRAIN.

For each fact create:

- fact/entity ID;
- training wording(s);
- answer;
- at least one held-out query wording;
- unrelated negatives.

Prevent entity leakage between train/eval constructions where appropriate.

TRAIN:

teacher_on = 1
learn = 1

Teacher supplies task supervision only.

FPGA performs:
encoding
similarity/error
learning
cue formation
memory bind/update.

EVAL:

teacher = 0
external_LLM = 0
learn = 0
freeze = 1

Required behavior:

held-out user query
→ encoder
→ retrieval
→ correct learned episode
→ answer path

At minimum pre-register these gates before running:

A. training facts:
100% stored/recallable unless a documented capacity error occurs

B. held-out wording:
target >= 90% correct on the locked set

C. unrelated negatives:
zero false accept on the locked negative set is preferred;
any false accept must be explicitly reported and quantified

D. no host-side answer lookup

E. reset/retrain:
old mapping becomes unavailable
new mapping is learned

Do not retune the dataset after seeing failures.

====================================================================
13. ANSWER PAYLOAD REQUIREMENT
====================================================================

Current 02M evidence is not enough by itself to claim mini-AI textual response
if it only returns a compact value/token.

For Kidi V1, implement the smallest honest answer payload mechanism required
for short factual answers.

Acceptable designs include:
- FPGA-owned token-sequence episode payload;
- DDR-backed episode payload;
- retrieved token sequence injected into the FPGA LM context.

Host may display returned tokens/text,
but must not choose the answer.

Do NOT implement:
if question == X:
    print(Y)

Do NOT keep an answer dictionary on the host in release proof.

====================================================================
14. PHASE NATIVE-V1 — INTEGRATE THE 802,816-PARAMETER LM
====================================================================

After A1 and Kidi retrieval close, create a NEW milestone:

A7-NATIVE-V1

Do NOT overwrite A7-LM-06.

Use LM-06 semantics as the primary language/controller model.

Locked primary model count:

P_LM = 802816

Do not call the entire system exactly "802816 parameters" if the 03E encoder
also contains trainable E/Wh weights.

Report separately:

P_LM
P_encoder
P_total_trainable
N_episodes

For current 03E architecture:

E:
256 x 32 = 8192 trainable values

Wh:
32 x 32 = 1024 trainable values

P_encoder = 9216

If both remain trainable in final system:

P_total_trainable = 812032

The fixed binary projection P is not counted as trainable if it remains fixed.

LM-06 hidden state MUST NOT be reused as the semantic cue.
02H already rejected that premise.

03E remains the episodic cue encoder.

Recommended dataflow:

user token sequence
      |
      +----------------------+
      |                      |
      v                      v
  03E encoder             LM/controller
      |                      ^
      v                      |
   64b cue                   |
      |                      |
      v                      |
  01R router                 |
      |                      |
      v                      |
  episode payload -----------+
      |
retrieved knowledge/context

Then:

LM/controller
→ next-token/output engine
→ FPGA argmax/sampling
→ response tokens

The LM must be ACTIVE in the output path for the mini-AI claim.
Do not keep 802,816 parameters merely loaded but functionally unused.

The retrieved episode may become context/token data.
It must not become a host-computed final answer.

Verify integrated LM behavior against frozen LM-06 arithmetic/oracle tests.

If LM-conditioned generation fails quality gates:
report NATIVE_V1_MINI_AI_FAIL.

Do NOT bypass it with a Python answer generator.

A retrieval-only system may still be reported as:
NATIVE_V1_MEMORY_CORE_PASS

but not as the completed mini-AI target requested here.

====================================================================
15. MINI-AI FINAL FUNCTIONAL CLAIM
====================================================================

The intended narrow claim is:

"An FPGA-native online-learning, memory-augmented small AI system with an
802,816-parameter DDR-resident Transformer backbone and a separately learned
episodic encoder, capable of learning novel post-bitstream facts, retrieving
relevant learned episodes from held-out short English queries, and producing
teacher-off FPGA-generated responses."

Do NOT claim:
- open-domain intelligence;
- LLM;
- general natural-language understanding;
- human-level semantics;
- ChatGPT equivalent;
- broad conversation;
- superiority to GPU/CPU;
- classical-string benchmark superiority unless measured.

====================================================================
16. SCALE LADDER — N_EPISODES, NOT PARAMETERS
====================================================================

Only begin scaling after the 20–40 fact system is scientifically closed.

Scale episode capacity in stages:

4096
16384
65536
262144
800000

Do not jump directly from 4096 to 800000.

The scale milestone is a NEW lane.
Do not modify the frozen 01R artifact in place.

Use frozen 01R behavior as a reference/oracle for overlapping small-scale tests.

For N_episodes scaling, a DDR-backed record/index implementation is allowed.

Preserve the logical retrieval contract unless a new contract explicitly
changes it.

At every scale measure:

N_episodes
bytes/episode
total record bytes
index bytes
posting bytes
candidate count/query
DDR reads/query
DDR writes/update
query latency
queries/s
false-hit rate
miss rate
overflow count
candidate dedup count
full-key Hamming checks
WNS/TNS
resource use

Do not claim O(1) or "constant-time memory" unless measured/proven.

Do not hide a linear scan.

If sparse retrieval is claimed:
measure candidate count as N grows.

At 800000 episodes require:

- successful insert/update;
- random exact retrieval tests;
- held-out approximate-cue tests;
- unrelated false-positive tests;
- teacher-off operation;
- reset/retrain or logical epoch invalidation;
- no host winner/address;
- no silent overflow;
- measured latency and bandwidth.

A capacity that merely stores 800000 records but cannot retrieve them usefully
does NOT pass.

====================================================================
17. DDR AND PARAMETER ACCOUNTING
====================================================================

Never mix these quantities:

P_LM
P_encoder
P_total_trainable
N_episodes
bytes_episode_storage

Example final reporting format:

P_LM              = 802816
P_encoder         = 9216
P_total_trainable = 812032
N_episodes        = 800000
episode_storage   = measured bytes
index_storage     = measured bytes

Do not write:

"1.6M parameter AI"

by adding episode count to parameter count.

Episodes are learned memory/state records,
not dense Transformer parameters.

====================================================================
18. PERFORMANCE MEASUREMENT
====================================================================

Once functional/learning gates pass, measure:

tokens/s
cycles/token
latency first token
latency subsequent token
MAC utilization
DDR read bandwidth
DDR write bandwidth
DMA stall cycles
candidate retrieval latency
encoder latency
LM latency
end-to-end user-query latency

Never infer throughput from theoretical DSP peak alone.

Board measurement takes authority over simulation for physical throughput.

Report simulation and board separately.

====================================================================
19. BOARD_PASS RULE FOR FINAL SYSTEM
====================================================================

A7-NATIVE-V1 BOARD_PASS requires ALL:

1. XSim/reference regressions PASS
2. timing:
   WNS >= 0
   TNS = 0
3. bitstream SHA frozen
4. silicon boot/protocol PASS
5. teacher TRAIN path PASS
6. teacher-off EVAL PASS
7. host HLB audit PASS
8. no hardcoded semantic mapping
9. held-out Kidi query gate PASS
10. reset/retrain PASS
11. LM/controller is active in output path
12. no post-freeze learning writes
13. frozen dependencies preserved
14. evidence archived

Anything less gets a narrower verdict.

====================================================================
20. RELEASE ANTI-HARDCODE AUDIT
====================================================================

Before final freeze search the entire repository for:

- prompt → answer maps;
- semantic ROM;
- test-string special cases;
- expected-answer lookup;
- host winner selection;
- hardcoded episode address;
- hidden hash injection;
- host gradient/update code;
- teacher calls during EVAL;
- external LLM calls during EVAL.

Release proof must show:

teacher = 0
external_LLM = 0
learn = 0
freeze = 1

AFTER/EVAL must create:
zero weight writes
and no episode mutation unless the evaluation contract explicitly enables it.

====================================================================
21. REQUIRED ARTIFACTS
====================================================================

Follow existing repository naming conventions where possible.

Create/freeze at least:

results/A7-EAM-03E/A01T_CLOSE/
results/A7-EAM-03E/A02_STABILITY/
results/A7-EAM-03E/A02_L/
results/A7-EAM-03E/A1/
results/A7-NATIVE-V1/KIDI/
results/A7-NATIVE-V1/INTEGRATION/
results/A7-NATIVE-V1/SCALE_800K/

Each result directory should contain where relevant:

manifest.json
closeout.md
timing summary
utilization summary
test ladder JSON
seed list
dataset SHA
bit SHA
source SHA
host tool SHA
before/after metrics
board transcript
failure notes

Create:

docs/contracts/A7-NATIVE-V1.md

before final integration implementation.

The contract must be frozen BEFORE confirmation-board runs,
not rewritten to match results afterward.

====================================================================
22. FINAL FREEZE
====================================================================

When all gates pass:

freeze:
- RTL;
- constraints;
- bitstream;
- dataset;
- teacher dataset;
- evaluation set;
- seed set;
- learning law ID;
- memory law ID;
- tokenizer;
- output protocol;
- scripts.

Generate:

A7-NATIVE-V1_CLOSEOUT.md

with:

STATUS
CLAIM
NOT_CLAIMED
BOARD
BIT SHA256
SOURCE SHA256
P_LM
P_encoder
P_total_trainable
N_episodes
TIMING
UTILIZATION
TOKENS/S
END-TO-END LATENCY
KIDI TRAIN RESULT
KIDI HELDOUT RESULT
FALSE POSITIVE RESULT
RESET/RETRAIN RESULT
TEACHER-OFF RESULT
ANTI-HARDCODE RESULT
MEMORY SCALE RESULT
KNOWN LIMITATIONS

====================================================================
23. GLASSBOX BOUNDARY
====================================================================

DO NOT implement GlassBox before Native V1 freeze.

No:
ILA changes
LiteScope
debug BRAM recorder
trace UART flood
interactive waveform UI
learning visualization UI

until the functional baseline is frozen.

After V1 is frozen, create only:

docs/architecture/GLASSBOX_READY.md

This document may identify future observation points such as:

interaction_id
token_id
encoder phase
h[0:31]
Wh telemetry
acc_max
sat_count
d_pos
d_neg
M_L1
M_cos
update_enable
weight_delta_count
64-bit cue
router candidate count
best_hamming
episode_id
DDR operation
retrieved payload
LM layer/state
pred token
learn/freeze state

Do not modify the frozen Native V1 bit to add these yet.

====================================================================
24. STOP CONDITIONS
====================================================================

STOP and report instead of hiding the problem if:

- T golden changes;
- WNS remains negative;
- long-horizon AUC collapses;
- effective rank collapses;
- seed 0x22222222 still inverts;
- triplet only improves training pairs but held-out fails;
- A1 only works on previously bound cues;
- host is required to choose answer/winner;
- LM is loaded but unused;
- Kidi result requires answer lookup on CPU;
- 800k scale becomes linear/full scan contrary to claim;
- DDR/index overflow is untracked;
- final timing is negative;
- teacher is needed in EVAL.

A negative result is valid research evidence.
Do not manufacture a PASS.

====================================================================
25. WORKING STYLE
====================================================================

Do not immediately rewrite the architecture.

Start by auditing repository state and producing a short reconciliation table:

MILESTONE
EXPECTED STATE
ACTUAL STATE
PASS/FAIL
NEXT ACTION

Then execute ONLY the first unresolved gate.

After each completed gate report:

WHAT CHANGED
WHY
FILES CHANGED
TESTS RUN
EXPECTED
ACTUAL
PASS/FAIL
ARTIFACT PATH
SHA256
NEXT GATE

Do not ask for confirmation between routine engineering steps unless:
- hardware is physically unavailable;
- a contract conflict exists;
- a destructive action is unavoidable;
- the next change would alter scientific law.

====================================================================
26. FIRST ACTION NOW
====================================================================

Do NOT start A0.2 immediately.

First:

1. inspect current rtl/eam/eam03e_core.sv;
2. compare against a01t_eupd frozen snapshot;
3. verify S_DIST/S_DADD patch;
4. run A0.1-T XSim;
5. compare exact 32-step golden;
6. if exact, run implementation;
7. report WNS/TNS/DSP.

Only after T is physically closed may the next learning-law phase begin.

The final objective is not to finish quickly.

The final objective is to produce a Native AI V1 result that survives
an adversarial scientific audit.

====================================================================
BOTTLENECK RESOLUTION OVERRIDE — MANDATORY
====================================================================

A STOP CONDITION means:

STOP DOWNSTREAM PROGRESSION.
DO NOT STOP ENGINEERING WORK.

When any required gate FAILS, you MUST autonomously continue working on that
same bottleneck until one of these outcomes is reached:

A. ROOT CAUSE FIXED AND GATE PASSES
B. THE HYPOTHESIS IS FALSIFIED BY REPRODUCIBLE EVIDENCE
C. A PHYSICAL / TOOL / HARDWARE LIMIT IS PROVEN AND DOCUMENTED

You MUST NOT pause merely to ask the user what to try next.

For every FAIL:

1. Reproduce the failure.
2. Freeze the failing evidence/artifacts.
3. Identify the smallest plausible root-cause set.
4. Rank hypotheses by likelihood and falsifiability.
5. Run the smallest experiment that can eliminate one hypothesis.
6. Inspect RTL, timing paths, arithmetic, state transitions, telemetry,
   testbench, host protocol, learning law and numerical range as applicable.
7. Apply ONE scientifically justified fix at a time.
8. Re-run regression + the failing gate.
9. If it still fails, use the new evidence to choose the next experiment.
10. Repeat until PASS or a genuine proven limit is reached.

You are explicitly authorized to:
- inspect and refactor RTL;
- pipeline datapaths;
- add temporary diagnostic telemetry;
- create focused testbenches;
- create reference/oracle scripts;
- run ablations;
- sweep pre-registered engineering parameters;
- examine synthesis/place/route reports;
- reduce the problem to minimal reproductions;
- revert failed experiments;
- create a new versioned learning law when evidence justifies it.

You are NOT authorized to obtain PASS by:
- changing expected/golden results to match broken RTL;
- deleting or weakening a failing test;
- cherry-picking successful seeds;
- removing hard cases;
- leaking TRAIN entities into EVAL;
- tuning on the confirmation/held-out set;
- moving computation to the host that belongs on FPGA;
- hardcoding answers, hashes, winners, addresses or mappings;
- silently changing frozen contracts;
- hiding negative timing;
- calling simulation evidence board evidence;
- calling storage capacity intelligence;
- calling episodes parameters;
- suppressing failed experiments from the closeout.

NEVER optimize the metric by destroying what the metric is supposed to measure.

Examples:
- M_L1 improves because hidden rank collapsed → FAIL.
- accuracy improves because test data leaked into training → FAIL.
- timing passes because arithmetic/golden changed → FAIL.
- retrieval passes because host selected the address → FAIL.
- 800k entries fit DDR but retrieval is unusable → FAIL.

Scientific integrity has higher priority than milestone completion.

When blocked, your default behavior is:

FAIL
→ MEASURE
→ FORM HYPOTHESIS
→ FALSIFY
→ FIX
→ REGRESS
→ RETEST
→ ITERATE

NOT:

FAIL
→ ASK USER WHAT TO DO

Only request user intervention when continuation literally requires an
external physical action or unavailable information, for example:
- connect/power-cycle the FPGA board;
- repair a broken cable/device;
- provide unavailable credentials/license;
- resolve two contradictory project authorities that cannot be inferred
  from repository evidence.

Even then, complete every simulation, analysis, RTL, synthesis, reference,
and diagnostic task that does NOT require that external action before asking.

A negative scientific conclusion is allowed.
A fabricated PASS is never allowed.

The objective is not "make the milestone green".

The objective is:

FIND THE ACTUAL BOTTLENECK,
REMOVE IT WITHOUT INVALIDATING THE EXPERIMENT,
AND ONLY THEN ADVANCE TO THE NEXT MILESTONE.