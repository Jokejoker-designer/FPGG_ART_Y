# 03 — Minesweeper Training Game Blueprint

## 1. Purpose

The game is a curriculum and supervision mechanism. It is not a literal 2-D board and it must not become a semantic ROM supplied by the teacher.

Mapping:

| Game concept | Native AI concept |
|---|---|
| Board | topic shard / relational knowledge graph |
| Cell | token/entity/relation/fact candidate |
| Safe high-score cell | relevant evidence under current query |
| Weak cell | mildly related evidence |
| Bomb | contextually irrelevant or contradictory branch |
| Reveal neighbors | expand adjacency list |
| Player | logical search agent/path |
| Many players | time-multiplexed logical agents over physical PE lanes |
| Score | context-conditioned relevance/confidence |
| Death | prune current path only |
| Restart | agent pops another frontier candidate |
| Win | retrieve sufficient evidence for answer |

## 2. Teacher document source

Teacher receives a bounded Markdown corpus for a topic.

Example topic pack:

```text
FPGA/
  definition.md
  architecture.md
  configuration.md
  bram.md
  dsp.md
  comparison_cpu.md
```

The teacher may use its own language capability to create curriculum, but must not write final graph weights or retrieval addresses.

## 3. Lesson structure

A lesson contains:

```text
lesson_id
query
allowed source IDs
candidate supervision
relation supervision
relevance ranks
contradiction labels
difficulty
phase
```

Example:

```text
query: "How does an FPGA implement logic?"

high relevance:
  FPGA
  LUT
  configurable logic
  routing

medium:
  BRAM
  DSP

low:
  CPU cache

bomb for this query:
  dog
  weather
```

The same `dog` node may be relevant in another query. Bomb status is query-conditioned.

## 4. Native move

Each active agent receives:

```text
current node
query state
path confidence
neighbor summary
```

It chooses/accepts a candidate through native score hardware. The teacher never sends the chosen winner.

## 5. Reveal rule

A node is expanded only when:

```text
score >= EXPAND_THRESHOLD
and
path_score >= PATH_THRESHOLD
```

Then the adjacency list is fetched and neighbors are pushed to frontier.

This avoids wasting DDR bandwidth on obvious bombs.

## 6. Bomb rule

A bomb means:

```text
PRUNE(path)
PENALIZE(local relation/path state)
RETURN agent to frontier
```

Never:

```text
RESET whole model
DELETE global node
PERMANENTLY blacklist token
```

## 7. Reward levels

Start with integer buckets:

```text
+3 strong relevant / correct relation
+1 useful but secondary
 0 neutral
-1 irrelevant
-3 contradiction / hard wrong branch
```

Teacher gives supervision. FPGA applies local update.

## 8. Grammar and sequence teaching

A flat co-occurrence graph is insufficient.

Example:

```text
"dog bites man"
"man bites dog"
```

must produce different relation paths.

Teach directed edges:

```text
DOG --SUBJECT_OF--> BITE
BITE --OBJECT--> MAN
```

versus:

```text
MAN --SUBJECT_OF--> BITE
BITE --OBJECT--> DOG
```

First V1 relation vocabulary should remain small and hardware-friendly.

## 9. Attention curriculum

Teacher must vary intent around the same entity.

For `FPGA`:

```text
DEFINE
MECHANISM
PART_OF
COMPARE
CAUSE
USE_CASE
```

The Native system must learn that the highest-score neighbors change with intent.

## 10. Multi-agent tournament

For one lesson:

```text
N logical agents start from different frontier candidates
↓
physical lanes score candidates in parallel
↓
Top-K paths survive
↓
weak/bomb paths are recycled
↓
agents continue until evidence budget or depth limit
```

Possible competition metrics:

```text
path relevance
coverage
contradiction count
redundancy
latency
```

Do not reward only lexical overlap.

## 11. Avoiding teacher shortcut learning

Mandatory training variations:

- paraphrases;
- different word order;
- synonyms;
- distractor topics;
- cross-topic negatives;
- contradiction examples;
- rare wording;
- same entity, different intent;
- same intent, different entity.

## 12. Blind exam

Teacher becomes examiner only after learning is frozen.

```text
teacher      = OFF for hints
external_LLM = OFF for reasoning
learn        = OFF
freeze       = ON
```

Exam inputs must not contain teacher-provided anchor labels, relevance scores or candidate lists.

## 13. Success definition

The game succeeds only when Native state supports new behavior after the teacher disappears.

A good training score with teacher assistance is not enough.
