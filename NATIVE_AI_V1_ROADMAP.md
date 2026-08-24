# NATIVE AI V1 — ROADMAP TO BOARD-CLOSED MINI MODEL ON ARTY A7-100T

**Project:** Native AI / A7-EAM-03E  
**Board:** Digilent Arty A7-100T (`xc7a100tcsg324-1`)  
**Goal:** Close a scientifically defensible Native AI V1 on FPGA before GlassBox integration.  
**Scientific rule:** `FITS != RUNS != TRAINS != CONVERGES != USEFUL`

---

## 0. FINAL TARGET

```text
User text
   ↓
UTF-8 / token IDs
   ↓
03E learned encoder
   ↓
64-bit learned cue
   ↓
01R sparse router
   ↓
02M episodic memory
   ↓
retrieved fact / context
   ↓
LM-06 Transformer
P_LM = 802,816
   ↓
FPGA next-token generation
   ↓
response tokens
```

TRAIN mode:

```text
Teacher
  ↓
text / A,P,N / SAME-DIFF / reward
  ↓
FPGA forward
  ↓
FPGA error / margin
  ↓
FPGA weight/state update
```

RELEASE / EVAL mode:

```text
teacher      = 0
external_LLM = 0
learn        = 0
freeze       = 1
```

The host may tokenize, log and display output.  
The host must not compute gradients, weight updates, cue/hash, internal winner, episode address or final answer.

---

## 1. LOCKED / FROZEN BASELINE

| Component | Status | Scope |
|---|---|---|
| A0.1-T | CLOSED | 100 MHz timing/arithmetic path |
| A0.3 signed-h | XSIM + SILICON EXACT | signed arithmetic defect fixed |
| S2 clamp | FALSIFIED | do not tighten clamp again |
| 01R | FROZEN / BOARD_PASS | sparse exact/near retrieval |
| 02M | FROZEN / BOARD_PASS | multi-cue episodic binding |
| LM-06 | FROZEN / BOARD_PASS | DDR-resident Transformer, `P_LM=802816` |
| A1 glue | CLOSED | encoder not yet strong enough |
| Kidi | CLOSED | waits for encoder freeze |
| GlassBox | CLOSED | starts only after Native AI V1 freeze |

Frozen artifacts must never be overwritten.

---

## 2. CURRENT BOTTLENECK — H5 DIFF GATE

Old law:

```text
gate_open = d1 < E3_MARG

if SAME:
    pull
elif DIFF and gate_open:
    push
else:
    no update
```

With:

```text
E3_MARG = 4096
typical untrained DIFF d1 ≈ 12k
```

many negative samples receive no repulsive update while SAME continues pulling.

Supporting evidence:

```text
seed 0x22222222

live gated law:  M_L1 = -1258
hinge m=0 copy:  M_L1 = +42
always-repel:    M_L1 = +1545

always-repel: 5/8
hinge:        1/8
```

Therefore the next causal experiment is:

> **Ungated DIFF first.**

Do not mix this experiment with S3, S2, triplet, normalization, 01R, 02M or LM-06.

---

## 3. PHASE E1 — UNGATED DIFF TWIN

**Law:** `eam03e-a03-ungated-diff-v1`

Single allowed change:

```text
OLD:
DIFF push only when d1 < 4096

NEW:
if learn:
    if same:
        pull
    else:
        push
```

Freeze everything else:

```text
signed h
E[256×32]
Wh[32×32]
fixed projection
d1 definition
tokenizer
update magnitude
dataset
preregistered seed set
```

Do not add:

```text
S1
S2
S3
triplet
cosine TRAIN
normalization
01R
02M
LM-06
```

Required telemetry:

```text
diff_seen
diff_push_count
diff_suppressed_count
d_pos
d_neg
M_L1
M_cos
AUC
AP
effective_rank
unique_d1
max_abs_h
fraction_h_clipped
Wh_l1
max_abs_Wh
Wh saturation
```

Hard sanity gate:

```text
diff_push_count == diff_seen
diff_suppressed_count == 0
```

---

## 4. E1 TWIN GO / NO-GO

### GO

Across preregistered seeds:

```text
d_pos and d_neg do not both collapse toward zero
effective_rank does not collapse toward 1
unique_d1 does not collapse toward 1
0x22222222 has M_L1 >= 0
DIFF is never suppressed during valid TRAIN
```

### NO-GO

If any seed still shows:

```text
rank collapse
Wh runaway
M_L1 inversion
distance degeneration
```

then H5 is not the sole cause.

Do not promote to RTL because one seed looks good.

---

## 5. LONG-HORIZON AUTHORITY

10k updates are no longer enough.

Every serious candidate law must be evaluated at:

```text
0
1k
5k
10k
20k
50k
100k
```

If still moving materially at 100k:

```text
200k
500k
```

for stable candidates only.

Required trends:

```text
AUC vs updates
AP vs updates
M_L1 vs updates
M_cos vs updates
rank vs updates
Wh_l1 vs updates
hidden saturation vs updates
unique_d1 vs updates
```

S3 evidence already showed that short-horizon non-inversion can be transient.

---

## 6. PHASE E2 — RECURRENT DRIFT, ONLY IF IT REMAINS AFTER H5

Question:

> After H5 is removed, does recurrent `Wh` still drift/run away?

Change one unknown per experiment.

### E2-A — S1

Reduce `Wh` learning rate/frequency while leaving `E` law unchanged.

Purpose:

```text
falsify F_wh
```

### E2-B — S3 decay

Only after H5 is isolated.

```text
Wh -= Wh >> k
k ∈ {3,4,5,6}
```

Each `k` is a separate registered experiment.

Selection priority:

```text
1. stability on all seeds
2. non-inversion on all seeds
3. worst ΔAUC
4. M_cos agreement
5. median ΔAUC
```

Do not choose a shift from one impressive seed peak.

---

## 7. PHASE E3 — GEOMETRY DIAGNOSIS

Enter only when:

```text
rank healthy
hidden saturation low
Wh stable
```

but representation quality remains weak.

Key disagreement:

```text
M_L1 > 0
M_cos < 0
```

Log:

```text
norm_A
norm_P
norm_N
rP = norm_P / norm_A
rN = norm_N / norm_A
M_L1
M_cos
```

Separate samples into:

```text
L1 agrees with cosine
L1 disagrees with cosine
```

Only if disagreement correlates with norm/radial asymmetry should normalization be opened.

---

## 8. PHASE E4 — BYTE ATTRIBUTION

Before changing architecture, test whether learning credit is assigned to the relevant bytes/timesteps.

```text
BASE:
chosen stable law

TEST:
BASE + byte attribution
```

Freeze seed set, dataset, horizon, margin and base law.

Questions:

```text
Does worst-seed AUC improve?
Does M_cos become consistently non-negative?
Does rank remain healthy?
Does long-horizon stability remain intact?
```

Do not combine attribution + new decay + new triplet in one experiment.

---

## 9. PHASE E5 — COMBINED (A,P,N)

Only after numerical stability.

Training transaction:

```text
(A, P, N)
```

must be atomic.

Concept:

```text
L = max(0, d(A,P) - d(A,N) + margin)
```

Hardware-friendly law:

```text
if margin violated:
    pull positive
    push negative
else:
    no update
```

Cosine remains **EVAL only** unless separately versioned later.

---

## 10. ENCODER FREEZE GATE

A1 stays CLOSED until all categories pass.

### Stability

```text
no effective-rank collapse
no full hidden saturation
unique_d1 > 1
no uncontrolled recurrent runaway
```

### Ordering

```text
M_L1 > 0
```

on all preregistered seeds at the registered horizon.

### Geometry

Target:

```text
M_cos >= 0
```

on all preregistered seeds.

### Generalization

```text
worst ΔAUC >= 0
median ΔAUC > 0
AUC_final > 0.5 on every seed
```

Any absolute target such as `median AUC >= X` must be preregistered before confirmation.

Always report:

```text
untrained encoder
classical string baselines
shuffled/null controls where appropriate
```

The encoder need not beat every classical string metric to prove online post-bitstream adaptation, but losses to classical baselines must be reported.

---

## 11. PHASE H — MOVE FROZEN LAW TO RTL

No RTL before twin law is frozen.

```text
freeze twin law
↓
new contract
↓
new RTL version
↓
XSim
↓
twin ↔ RTL exact regression
↓
synthesis
↓
implementation
↓
WNS >= 0
TNS = 0
↓
new bitstream
↓
SHA256 archive
↓
silicon test
```

Never overwrite A0.1-T, A0.3, 01R, 02M or LM-06 artifacts.

---

## 12. ENCODER BOARD_PASS RULE

A new encoder law is not BOARD_PASS until:

```text
XSim exact PASS
twin/RTL arithmetic agreement PASS
WNS >= 0
TNS = 0
bit SHA frozen
silicon arithmetic PASS
learning behavior on board matches frozen law
```

Simulation throughput is not silicon evidence.

---

## 13. PHASE K1 — KIDI-20

After encoder freeze:

```text
20 English facts
```

Each fact:

```text
fact/entity ID
training wording
positive wording
negative wording
answer
held-out query wording
```

TRAIN:

```text
teacher = 1
learn   = 1
```

FPGA performs encoding, learning, cue formation and memory bind/update.

Host must not compute cue or memory winner.

---

## 14. PHASE K2 — KIDI-40 TEACHER-OFF

Scale to 40 facts.

Then:

```text
teacher      = 0
external_LLM = 0
learn        = 0
freeze       = 1
```

Use held-out queries.

Required:

```text
correct fact retrieval
unrelated rejection
no host answer lookup
no memory mutation during frozen EVAL
reset/retrain
```

Held-out wording must not have been explicitly bound if generalization is claimed.

---

## 15. PHASE A1 — GLUE 03E → 01R → 02M

Only after encoder/Kidi gates.

```text
text
 ↓
03E
 ↓
64-bit learned cue
 ↓
01R
 ↓
02M
```

Do not retune frozen router thresholds to rescue encoder weakness.

Required:

```text
exact cue hit
learned similar cue hit
held-out formulation hit
unrelated reject
teacher-off recall
reset/retrain
host never sends winner/way/address/hash
```

If only explicitly bound cues succeed:

```text
MEMORY PASS
GENERALIZATION NOT PROVEN
```

---

## 16. MEMORY SCALE LADDER

Do not jump directly to 800k.

```text
20
40
256
4096
16384
65536
262144
800000 episodes
```

At every scale measure:

```text
candidate count/query
DDR reads/query
DDR writes/update
query latency
queries/s
false-hit rate
miss rate
overflow
dedup count
memory bytes
index bytes
```

Do not claim sparse/constant retrieval if it becomes a full scan.

---

## 17. PHASE L — LM-06 INTEGRATION

Only after episodic retrieval closes.

```text
User query
      │
      ├────→ 03E → 01R → 02M
      │                    ↓
      │             retrieved payload
      │                    ↓
      └──────────────→ LM-06 context
                           ↓
                     FPGA next token
                           ↓
                       response
```

LM-06 must be active in the output path.

Host may send input, receive tokens and display text.  
Host must not choose or generate the answer.

---

## 18. PARAMETER ACCOUNTING

```text
P_LM = 802,816

Embedding:
256 × 32 = 8,192

Wh:
32 × 32 = 1,024

P_encoder = 9,216

If both are trainable:
P_total_trainable = 812,032
```

Memory is separate:

```text
N_episodes = up to 800,000
```

Episodes are learned state/memory records, not dense parameters.

---

## 19. FINAL NATIVE AI V1 PROOF

```text
fixed bitstream
↓
new facts introduced after programming
↓
FPGA learns representation
↓
FPGA changes learned state / memory
↓
teacher OFF
↓
held-out user query
↓
FPGA encoder
↓
FPGA episodic retrieval
↓
LM-06 consumes retrieved knowledge
↓
FPGA generates response tokens
```

Then:

```text
reset / forget
↓
old learned behavior disappears
↓
different mapping is trained
↓
new learned behavior appears
```

---

## 20. FINAL CLAIM

Acceptable final claim:

> **An FPGA-native online-learning, memory-augmented small AI system on the Arty A7-100T, using an 802,816-parameter DDR-resident Transformer backbone plus a separately learned episodic encoder, capable of learning novel post-bitstream facts, retrieving learned episodes from held-out short English queries, and producing teacher-off FPGA-generated responses.**

Do not claim LLM, open-domain chatbot, AGI, ChatGPT equivalence, broad semantic understanding or GPU superiority without separate evidence.

---

## 21. PASS HIERARCHY

```text
ENCODER_STABILITY_PASS
ENCODER_GEOMETRY_PASS
ENCODER_BOARD_PASS

KIDI20_PASS
KIDI40_TEACHER_OFF_PASS

A1_EAM_INTEGRATION_PASS

SCALE_800K_PASS

NATIVE_V1_MEMORY_CORE_PASS

NATIVE_V1_MINI_AI_BOARD_PASS
```

Never promote a narrow PASS into a broader claim.

---

## 22. FAILURE BRANCHES

### Ungated DIFF fails
Measure recurrent drift, then test S1 independently.  
Test S3 independently only after H5 is cleanly isolated.

### Rank healthy but M_cos negative
Diagnose radial/norm asymmetry, then test byte attribution before normalization.

### Attribution fails
Only then open a separately-versioned normalization experiment.

### Triplet improves TRAIN but held-out AUC fails
Treat as pair fitting, not reusable representation. A1 remains CLOSED.

### Kidi exact recall passes but held-out wording fails
Claim episodic/multi-cue memory, not semantic generalization.

### LM-06 needs host answer generation
Mini-AI final gate fails. Do not hide it with Python.

---

## 23. PROVENANCE CONTROL

For every experiment archive:

```text
law ID
twin SHA
tool SHA
exact command
seed list
dataset SHA
horizon
parameters
start/end timestamps
per-seed outputs
output SHA256
plots
PASS/FAIL
negative findings
```

One unknown per experiment.

Peer observer remains read-only unless explicitly promoted.

Never:

```text
change golden to fit broken RTL
drop failing seeds
tune on confirmation set
rewrite failed history silently
```

Corrections remain visible.

---

## 24. GLASSBOX START CONDITION

GlassBox begins only after:

```text
NATIVE_V1_MINI_AI_BOARD_PASS
```

or an explicitly accepted narrower Native V1 freeze.

GlassBox observes the frozen model; it must not change the learning law.

---

## 25. MASTER EXECUTION ORDER

```text
CURRENT
  ↓
E1  ungated-DIFF twin
  ↓
long-horizon / all preregistered seeds
  ↓
E2  isolate Wh drift only if present
  ↓
E3  geometry diagnosis
  ↓
E4  byte attribution if justified
  ↓
E5  combined (A,P,N) if justified
  ↓
ENCODER FREEZE
  ↓
RTL
  ↓
XSIM
  ↓
TIMING
  ↓
SILICON
  ↓
ENCODER_BOARD_PASS
  ↓
KIDI-20
  ↓
KIDI-40 TEACHER-OFF
  ↓
A1: 03E → 01R → 02M
  ↓
MEMORY SCALE LADDER
  ↓
800K EPISODES
  ↓
LM-06 INTEGRATION
  ↓
END-TO-END TEACHER-OFF
  ↓
RESET / RETRAIN
  ↓
NATIVE_V1_MINI_AI_BOARD_PASS
  ↓
GLASSBOX
```

---

## 26. IMMEDIATE NEXT ACTION

```text
Implement and preregister:
eam03e-a03-ungated-diff-v1

Twin only.
No decay.
No triplet.
No glue.

Run all preregistered seeds.
Measure through long horizon.
Archive provenance.
PASS/FAIL H5 cleanly.
```

That result decides the next branch.
