# SEV-0 — NG-02 Top-K is pair-winners, not global Top-8

**Status:** OPEN (reopens `ng02` DONE_ENG claim)  
**Archived NG-02 XSim/board:** PASS under *pair-winner* TB contract  
**Global Top-8 contract:** FAIL / NOT IMPLEMENTED  
**Authority:** human P0 review 2026-08-21; goal still `NATIVE_V1_MINI_AI_BOARD_PASS`

## Defect

`rtl/native_graph/topk/a7ng_topk.sv` reduces 16 candidates by 8 independent pairs:

```text
(c0,c1)→w0  (c2,c3)→w1  …  (c14,c15)→w7
```

That yields **8 pair winners**, not the **8 globally best** scores.

Counterexample: pair0={100,99}, pair1={10,9}, … → true Top-8 must keep 100 **and** 99; pair network drops 99.

Worse: existing TB encodes pair-winner behavior → XSim PASS does not prove Top-K.

## Research branch (do not overwrite NG-02 evidence)

```text
results/A7-NATIVE-GRAPH/NG-02R-TOPK/
```

Compare three implementations (FANNS-aligned primitives):

1. full bitonic 16→8  
2. exact partial-selection network  
3. systolic priority queue (multi-input)

Pick one for silicon; archive comparison numbers.

## Hard stop (one mismatch = FAIL)

```text
100_000 random vectors
+ ties
+ signed scores
+ valid masks

RTL Top8 == Python oracle Top8  for EVERY case
```

New law id / marker required (do not reuse A7NG02 archived SHA as proof of global Top-8).

## Related P0 (next after Top-K)

See `STATUS/P0_P1_BACKLOG.md` — NG-02R-FLOW backpressure before claiming batch safety.
