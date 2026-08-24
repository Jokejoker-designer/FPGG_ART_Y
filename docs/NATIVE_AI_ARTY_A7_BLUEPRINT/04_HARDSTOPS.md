# 04 — Consolidated Hard Stops

These are non-negotiable. A violation blocks downstream promotion.

## HS-01 — Host learning boundary

Host/teacher must not compute or send:

```text
gradient
ΔW
updated weight
internal hash/cue
winner
way
memory address
retrieval answer
next token
final answer
```

Allowed host responsibilities:

```text
files/tokenization/UI/logging
teacher questions
labels/relevance/reward
curriculum
external audit
```

## HS-02 — Teacher-off proof

No Native AI success claim without:

```text
teacher=0
external_LLM=0
learn=0
freeze=1
```

and held-out queries.

## HS-03 — No semantic ROM

No prompt→answer table, topic→answer table, precomputed winner table or hidden semantic lookup compiled into the bitstream.

## HS-04 — No attention leakage

During final exam the teacher may not send:

```text
main token
entity
intent
candidate ranking
relation path
```

Native hardware must derive them.

## HS-05 — No graph pre-answering

Teacher can supervise graph learning but cannot write a finished answer graph that encodes the exam answers directly.

## HS-06 — Bomb is contextual

No token/node is permanently marked irrelevant from one query. Bomb/prune is conditioned on query/context/path.

## HS-07 — No global reset on path failure

Wrong path may be killed or penalized. It may not reset unrelated learned state.

## HS-08 — Typed/ordered relations required

Do not claim grammar/structured knowledge from token co-occurrence alone.

## HS-09 — Physical parallelism honesty

If there are 16 physical PEs serving 8,000 logical agents, claim:

> 16 physically parallel lanes, time-multiplexing 8,000 logical agent contexts.

Never claim 8,000 physically parallel AI cores.

## HS-10 — Full-model copy honesty

A single LM-06 currently uses 59.2% LUT, 97.8% BRAM and 64.2% DSP. The board cannot host two current full LM-06 instances.

## HS-11 — Resource fit

Integrated post-route must satisfy device resources. Naive BRAM sum 243/135 is an architectural FAIL, not a warning.

## HS-12 — Timing

No BOARD_PASS when:

```text
WNS < 0
or TNS != 0
```

for the declared clock domain.

## HS-13 — No hidden linear scan

An 800k-episode system cannot claim sparse retrieval if every query scans all 800k records.

Record candidate/query and DDR bytes/query.

## HS-14 — DDR address authority

FPGA must generate graph/episode addresses from Native state. Host cannot send the winning address.

## HS-15 — Training/eval separation

No training example, teacher score or answer label may leak into the blind confirmation set.

## HS-16 — Confirmation set protection

Do not tune thresholds, graph schema or learning rate after reading confirmation results.

## HS-17 — Gate immutability

Preregister pass/fail criteria before the confirmation run. Do not lower rank/AUC/margin gates because a favorite candidate misses them.

## HS-18 — Long-horizon authority

Do not promote a learning law solely from an early peak when longer registered horizons reverse the verdict.

## HS-19 — Evidence scope

```text
TWIN != RTL
RTL != XSIM PASS
XSIM PASS != IMPLEMENTED
IMPLEMENTED != BOARD
BOARD arithmetic != semantic/generalization proof
```

## HS-20 — Frozen artifacts

Never overwrite frozen A0.3, 01R, 02M or LM-06 bitstreams/results.

## HS-21 — Parameter accounting

Keep separate:

```text
P_LM
P_encoder
P_total_trainable
N_episodes
N_graph_nodes
N_edges
```

Episodes/nodes are not dense model parameters.

## HS-22 — LM participation

If final claim includes LM-06, LM-06 must be active in the FPGA output path. A Python/PC answer generator invalidates the claim.

## HS-23 — Frequency is not semantics

Token frequency may be one feature but cannot be the sole relevance authority.

## HS-24 — No architecture victory by benchmark leakage

A graph trained and evaluated on the same phrasings is not evidence of language generalization.

## HS-25 — Independent failure channels

Do not fix multiple hypotheses in one experiment unless the experiment is explicitly a combined confirmation after each component was individually justified.
