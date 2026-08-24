# 06 — Knowledge Graph and Native Attention

## 1. Node record

Suggested compact logical fields:

```text
node_id
type
topic_id
base_confidence
context_tag
first_edge
edge_count
flags
```

Actual packed width must be optimized after DDR burst experiments.

## 2. Edge record

Suggested fields:

```text
dst_id
relation_type
base_weight
context_delta/confidence
flags
```

Keep edges directed.

## 3. Topic sharding

DDR should be organized so common queries can load contiguous shards.

Example:

```text
hardware
  FPGA
  CPU
  GPU
animals
language
...
```

Topic shard is an index/storage optimization, not a semantic answer ROM.

## 4. Query feature vector

V1 should keep it small:

```text
entity cue(s)
intent class/context cue
sequence cue
current topic confidence
```

Do not require a dense 768-D embedding to prove the concept.

## 5. Native attention shift

Same entity, different intent must change ranking.

```text
FPGA + DEFINE
→ programmable logic device
→ configurable hardware

FPGA + MECHANISM
→ LUT
→ routing
→ configuration memory

FPGA + COMPARE + CPU
→ reconfigurable hardware
→ parallelism
→ instruction execution differences
```

## 6. Path score

Recommended recurrence:

```text
new_path_score = saturate(
    old_path_score
  + node_score
  + relation_score
  + context_score
  - contradiction_penalty
  - depth_penalty
)
```

Depth penalty is optional but useful to prevent endless expansion.

## 7. Evidence diversity

Top-K must avoid returning K copies of the same fact.

Possible low-cost diversity rule:

```text
same fact/topic/path signature
→ small redundancy penalty
```

## 8. Knowledge write policy

Do not permanently write every transient path.

Possible V1 policy:

```text
reward consistency >= threshold
or repeated teacher confirmation
→ promote edge/fact confidence
```

Negative reward reduces confidence; it does not necessarily delete immediately.

## 9. Contradiction handling

Contradiction must be explicit where possible.

Example:

```text
FPGA --IS_A--> programmable logic device
FPGA --IS_A--> dog
```

The second relation can receive a strong negative update while the `dog` node itself remains valid elsewhere.

## 10. Native attention gate

Final blind exam must prove the FPGA can extract enough query state to choose different graph paths without teacher-supplied intent.
