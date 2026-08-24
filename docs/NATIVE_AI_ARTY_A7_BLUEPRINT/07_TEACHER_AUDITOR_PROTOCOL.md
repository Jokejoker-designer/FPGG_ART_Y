# 07 — Teacher / Auditor Protocol

## 1. Roles

Use separate logical roles even if both are implemented by the same external model provider.

```text
CURRICULUM TEACHER
→ creates lessons

GRADER
→ scores relevance/relations/output during TRAIN

EXAMINER/AUDITOR
→ creates held-out questions and checks evidence
```

## 2. Teacher may send

```text
lesson ID
question/input tokens
source-document IDs
candidate labels for training
relative relevance ranks
relation labels
reward bucket
difficulty
phase
```

## 3. Teacher may not send

```text
gradient
Δweight
updated graph weight
selected winner
internal cue/hash
DDR address
next-token choice
final answer during release
```

## 4. Curriculum from Markdown

Teacher reads bounded topic documents and creates:

- direct questions;
- paraphrases;
- same-entity/different-intent questions;
- distractors;
- contradictions;
- cross-topic negatives;
- blind exam questions.

## 5. Ranking rather than absolute semantics

Teacher supervision should often express relative ordering:

```text
A > B > C > D
```

This is more robust than pretending the teacher's numeric score is an objective truth.

FPGA can learn from ranking violations locally.

## 6. Audit evidence

Auditor receives:

```text
query
Native output
retrieved evidence IDs
scores
hardware provenance
```

It may grade correctness but cannot repair the answer during the exam.

## 7. Model-provider independence

Protocol should support adapters for:

```text
Grok
OpenAI
Claude
Gemini
local Ollama/LM Studio
MCP/custom local model
```

The FPGA protocol must not depend on one provider's private attention tensors.

## 8. Teacher quality risk

The system is highly teacher-dependent during curriculum generation. Mitigate with:

- multiple prompt templates;
- optional multi-teacher disagreement checks;
- held-out examiner;
- source-grounded scoring;
- contradiction tests;
- randomization of wording;
- audit log of every lesson.

## 9. Final release

No external model is required for inference after Native V1 has been trained and frozen.
