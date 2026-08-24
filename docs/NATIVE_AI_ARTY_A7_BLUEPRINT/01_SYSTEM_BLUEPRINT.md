# 01 — System Blueprint

## 1. Product objective

Build a Native AI that treats FPGA parallelism as a first-class architectural resource. The final inference path is not a CPU-style loop translated to RTL. It is a sparse, parallel, context-conditioned graph search with local learning.

```text
USER QUERY
    ↓
NATIVE QUERY ATTENTION
(entity + intent + context + sequence cues)
    ↓
CANDIDATE ROUTER / TOPIC SHARD SELECTOR
    ↓
DDR KNOWLEDGE GRAPH
    ↓
BRAM HOTSET / FRONTIER CACHE
    ↓
PHYSICAL PARALLEL AGENT LANES
    ↓
TOP-K REDUCTION + PATH PRUNING
    ↓
STRUCTURED EVIDENCE BUFFER
    ↓
LM-06 LANGUAGE COMPOSER
    ↓
FPGA NEXT-TOKEN OUTPUT
```

## 2. Native knowledge hierarchy

Do not make the memory a flat token bag. Use at least:

```text
TOPIC
  ↓
ENTITY / INTENT
  ↓
FACT / EPISODE
  ↓
RELATION / SEQUENCE
  ↓
TOKEN
```

Recommended node types:

- `TOKEN`
- `ENTITY`
- `INTENT`
- `RELATION`
- `FACT`
- `EPISODE`
- `TOPIC`
- `CONTRADICTION`

Recommended relation types:

- `IS_A`
- `HAS`
- `PART_OF`
- `CAN_DO`
- `CAUSES`
- `DEFINES`
- `SUBJECT_OF`
- `OBJECT_OF`
- `BEFORE`
- `AFTER`
- `NEAR`
- `COMPARES_WITH`

## 3. Query attention

For the query:

```text
"FPGA là gì?"
```

the Native system should learn to produce:

```text
ENTITY = FPGA
INTENT = DEFINE
CONTEXT = HARDWARE
```

For:

```text
"FPGA hoạt động ra sao?"
```

it should produce:

```text
ENTITY = FPGA
INTENT = MECHANISM
CONTEXT = HARDWARE
```

For:

```text
"FPGA có thể nhận diện con chó trong camera không?"
```

`dog` is not a permanent bomb. It becomes a valid secondary entity because context and intent changed.

Therefore irrelevance must be represented as:

```text
PRUNE_SCORE(node | query, intent, context, path)
```

not:

```text
DOG = BOMB
```

## 4. Sparse relational attention

The graph engine should implement a hardware-friendly attention analogue:

```text
query anchors
    ↓
sparse candidate retrieval
    ↓
parallel candidate scoring
    ↓
top-K frontier
    ↓
neighbor expansion
    ↓
contextual pruning
```

Do not call this Transformer attention. Recommended term:

> **Sparse Relational Attention**

## 5. Fixed-point score

A first hardware law may use signed integers:

```text
Score = EntityMatch
      + IntentMatch
      + RelationMatch
      + ContextMatch
      + PathConfidence
      + LearnedPrior
      - ContradictionPenalty
```

Each term should be independently observable. Use saturation arithmetic. Avoid floating point unless later evidence requires it.

## 6. Search path semantics

Knowledge resides in shared memory. Agents are workers, not independent full AIs.

```text
agent context = current node + score + depth + state + path signature
```

A low-score/bomb node causes:

```text
PRUNE CURRENT PATH
RETURN AGENT TO FRONTIER
```

It must never erase unrelated learned knowledge.

## 7. Structured evidence to LM-06

LM-06 should receive structured evidence, not only top words:

```text
QUERY
entity=FPGA
intent=DEFINE

PATH 1
FPGA --IS_A--> programmable logic device
score=241

PATH 2
FPGA --HAS--> configurable logic blocks
score=215

PATH 3
FPGA --CAN_BE--> reconfigured after manufacturing
score=196
```

LM-06 then composes a sentence. The host must not compose the answer.

## 8. Training architecture

```text
PC TEACHER
  │  question / relevance ranks / relation labels / rewards
  ▼
FPGA QUERY + GRAPH ENGINE
  │  native search / local error / local update
  ▼
FPGA SHARED KNOWLEDGE MEMORY
  │
  └──── telemetry ────> PC AUDITOR
```

Teacher decides **what to teach**. FPGA decides **how state changes**.

## 9. Evaluation architecture

```text
teacher      = OFF
external_LLM = OFF
learn        = OFF
freeze       = ON
```

Native system must independently detect query anchors, retrieve evidence and generate the answer.

## 10. Existing project reuse

- 01R concepts can become the sparse candidate-router/final Hamming authority.
- 02M concepts can become episodic/fact payload memory.
- LM-06 becomes the language composer.
- 03E remains an encoder research lane. It may later become the native query encoder if it passes its own gates; the graph branch must not silently inherit an encoder that is still weak.
