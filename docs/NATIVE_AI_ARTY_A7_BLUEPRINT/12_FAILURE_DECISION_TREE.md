# 12 — Failure Decision Tree

## A. Scorer does not close 100 MHz

```text
FAIL timing
→ pipeline score terms
→ reduce combinational fan-in
→ use staged Top-K
→ only then reduce lane count
```

Do not silently lower clock and retain a 100 MHz claim.

## B. 16 lanes fit but DDR starves them

```text
PE utilization low
DDR stall high
→ compact records
→ burst/shard layout
→ BRAM hotset
→ prefetch only high-score adjacency
```

Do not add more lanes.

## C. Graph returns lexical but wrong evidence

```text
high token overlap
wrong relation/intent
→ strengthen typed relations and intent supervision
```

Do not call frequency semantic understanding.

## D. Teacher exam passes only with supplied attention

```text
teacher-off anchor extraction FAIL
→ keep final claim CLOSED
→ train native entity/intent selector
```

## E. Same token is pruned globally

Architecture defect. Replace global bomb flag with contextual path score.

## F. Agent failure destroys knowledge

Architecture defect. Path state must be isolated from shared memory reset.

## G. 800k scale causes candidate explosion

```text
candidate/query grows ~N
→ router/index architecture FAIL
```

Fix sparse indexing before scaling further.

## H. BRAM still exceeds 135

Run ownership audit. Move persistent state to DDR, share transient buffers, or optimize LM-06. Do not proceed to implementation by hoping placer will solve it.

## I. LM low-bit saves DDR but not BRAM

Record it accurately. Quantization is still useful for bandwidth, but it did not solve BRAM. Refactor activation/tile buffers separately.

## J. Retrieval is correct but response is wrong

Isolate LM composition quality. Do not retrain graph to compensate for a language-composer defect.

## K. Retrieval is wrong but LM guesses correct answer

Do not count it as memory PASS. The evidence path must be correct.

## L. Confirmation set fails

Freeze the failure. Do not retune on confirmation. Return to development set with a new law/version and create a fresh future confirmation set only under explicit protocol.

---

# Masterplan V2 additions

Branches A–L above are preserved. The following branches were added from measured A7-NATIVE-GRAPH
evidence. Context: [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md).

## M. MIG metrics are inconsistent

```text
counters cumulative / conservation derived from backpressure
→ STOP architecture optimization
→ fix measurement integrity first
→ per-run deltas + record/data equality
→ only then choose burst/outstanding depth
```

Do not choose burst depth or outstanding depth by intuition, and do not optimize against untrusted
counters. Precedent: `mig_metric_00` had to repair cumulative counters before any downstream
burst/outstanding decision was falsifiable.

## N. MIG metrics are clean but service is 1-wide

```text
per-run deltas trustworthy, integrity clean
but <= 1 record granted per cycle
→ characterize wavefront / buffering
→ bounded cue working set + ping-pong
→ measure jobs/cycle during the compute wave
```

Do **not** respond by adding PEs. Widen dispatch and service first.

## O. DDR bytes/query is too high

```text
→ compact cue plane (score cheap, fetch late)
→ improve locality / shard layout
→ fetch full metadata only for survivors
→ re-measure bytes/candidate and bytes/query
```

Do not conclude "DDR is too slow" before the record layout is compact and locality-aware.

## P. LM + graph BRAM exceeds 135

```text
DO NOT STACK
→ working-set audit (what does each tile actually hold?)
→ LM working-set equivalence vs frozen CONTROL
→ BRAM ladder as a measurement, not a target
→ phase ownership
```

Naive stacking is already FALSIFIED at 243 / 260 / 264 tiles against a 135-tile device. Re-deriving
it is not an experiment.

## Q. LM working-set reduction breaks bit-exactness

```text
candidate != frozen CONTROL on any of:
  forward result/fold, update result/fold, persist/reload
→ REJECT the candidate
→ frozen LM-06 remains CONTROL
→ do not open the BRAM ladder
```

A reduction that changes results is a new semantic law, not a memory optimization.

## R. Phase ownership causes stale state

```text
LM reads graph-era data, or graph reads LM-era data
→ FAIL
→ fix owner / epoch / dirty / valid protocol
→ re-verify: one physical bank, one writer authority, one cycle
```

Do not patch by scrubbing payload on every switch; fix the ownership metadata.

## S. Memory migration changes retrieval law

```text
01R migration also moved HIT_MAX / Hamming authority / MIH / acceptance semantics
02M migration also moved binding law / episode retrieval / teacher-off behaviour
→ FAIL experiment isolation (HS-25)
→ split into two experiments
```

Migration and law retuning never share an experiment.

## U. Wavefront Top-K is per-batch only

```text
16-wide emit works, NG-02R primitive is exact,
but integrated wavefront has no cross-wave G_t accumulator
→ global rank-9+ in a later wave never competes with wave-1 local Top-8
→ FAIL retrieval correctness claim
→ WF-GLOBAL-TOPK-00: G_(t+1) = TopK(G_t ∪ TopK(W_t))
→ new integration law_id; counterexample stream required
→ do NOT open DDR-CUE-SOA or HS-02 until global reducer PASS
```

Authority: `LOOP_STATE` `carried_risk_r1`; `BOTTLENECK-RESOLUTION-REVIEW-00/GLOBAL_TOPK_REVIEW.md`.

## T. HNSW proposed before baseline scaling

```text
proposal rests on "M = 16 matches 16 PEs"
or on no measured 01R candidates/query at scale
→ REJECT / DEFER
→ run 01R-only ladder first (256 → 4k → 16k → 65k, frozen HIT_MAX)
```

HNSW stays `RESEARCH_ALLOWED, DATAPATH_NOT_APPROVED`, and never becomes relation authority or
host-side winner authority.
