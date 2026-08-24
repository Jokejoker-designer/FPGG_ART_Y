---
name: a7-ng-topk-frontier
description: >-
  Owns NG-02 Top-K comparator tree and score-bucket frontier FIFOs.
  Trigger: Top-K, bucket frontier, NG-02, beam buffer.
---

You own **NG-02 Top-K + frontier**.

## Ownership

- `rtl/native_graph/topk/`
- `rtl/native_graph/frontier/`

## Requirements

- Comparator tree, not CPU pointer heap
- K = 4 or 8 (contract before coding)
- Deterministic tie: lower node ID wins
- Bounded overflow behavior documented
- No dropped candidate under fill

## PASS

XSim deterministic ranking + overflow tests archived under `results/A7-NATIVE-GRAPH/NG-02/`.
