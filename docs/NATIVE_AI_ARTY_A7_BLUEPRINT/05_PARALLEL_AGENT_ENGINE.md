# 05 — Parallel Agent Engine

## 1. Definitions

- **Physical PE/lane:** real hardware operating in parallel in the same cycle.
- **Logical agent:** a search context scheduled onto a physical lane.
- **Full Native AI instance:** complete query+memory+LM system. Current resources support only one LM-06-scale full instance.

## 2. Initial target

Recommended first implementation:

```text
16 physical lanes
256 logical contexts
K=8 survivor paths
100 MHz
```

Scale physical lanes only after post-route evidence.

## 3. Lane datapath

Each lane may contain:

```text
candidate register
query feature register
relation decoder
context comparator
path-score accumulator
contradiction detector
saturating adder
threshold flags
```

Output:

```text
candidate_id
score
expand
prune
relation_type
```

## 4. Pipeline

Target initiation interval:

```text
II = 1 candidate/lane/cycle
```

after pipeline fill for BRAM-resident records.

Theoretical compute ceiling at 100 MHz:

```text
16 lanes → 1.6 G candidate-scores/s
32 lanes → 3.2 G candidate-scores/s
64 lanes → 6.4 G candidate-scores/s
```

These are compute ceilings, not end-to-end throughput. DDR bandwidth will usually be lower.

## 5. Top-K reduction

Use comparator tree rather than serial CPU sorting.

```text
PE outputs
  ↓
pairwise compare
  ↓
partial winners
  ↓
K winners
```

Tie rule must be deterministic, e.g. lower node ID wins equal score.

## 6. Frontier

Avoid a pointer-heavy heap. Recommended choices:

1. score-bucket FIFOs;
2. fixed-width beam buffer;
3. two-level priority buckets.

A 16-bin or 32-bin quantized score frontier maps cleanly to FPGA.

## 7. Logical context

Conservative 16-byte context example:

```text
node_id       32 bits
path_score    16 bits
depth          8 bits
flags          8 bits
parent/hash    32 bits
query_ref      16 bits
relation/state 16 bits
```

16 bytes/context means:

```text
64 KiB  → 4,096 logical contexts
128 KiB → 8,192 logical contexts
```

These contexts are not physically simultaneous.

## 8. Loop control

Each query has limits:

```text
max expansions
max depth
max DDR bytes
max active contexts
min evidence confidence
```

This prevents infinite graph wandering.

## 9. Shared arithmetic opportunity

Graph retrieval and LM generation are naturally phased:

```text
RETRIEVE → COMPOSE
```

If LM-06 arithmetic resources are idle during retrieval, a future integrated design may reuse part of the arithmetic fabric for graph scoring. Do not assume this saving until synthesized.

## 10. Parallel learning

Candidate/node/edge local updates can also be issued by multiple lanes if writes do not conflict.

Required conflict policy:

```text
same address collision
→ deterministic reduction/serialization
```

Never silently lose one update.

## 11. DDR write coalescing

Do not random-write every tiny reward directly to DDR when avoidable.

Prefer:

```text
BRAM/LUTRAM local delta cache
→ combine repeated updates
→ burst/coalesced flush
```

This is essential because graph learning may otherwise become memory-write bound.
