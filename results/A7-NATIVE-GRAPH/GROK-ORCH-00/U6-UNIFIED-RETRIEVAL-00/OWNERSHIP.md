# U6 SOURCE OWNERSHIP AUDIT (before RTL edit)

BASE = `5aa8285533b0f4a571dac5328b28a1f8a5ef5fc1`

## Map (modules that exist in this tree)

```text
SOURCE
  AUTHORITATIVE (U4/U5):  rtl/native_graph/memory/a7ng_sparse_dir_axi.sv
                          cand_v / cand_id[19:0] / q_done / q_overflow_o / n_trunc_o

  LEGACY / SYNTHETIC (must not reach U6 Top-K):
    rtl/native_graph/integrate/a7ng_learned_prior_graph.sv
      cand_nid / cand_s / cand_r / cand_o / mix_terms / fi_of(qid)
    rtl/native_graph/learn/a7ng_causal_learn_fast.sv
      gi_of(qid, feed_i) → g_id / base_terms
    rtl/native_graph/learn/a7ng_persist_gen_fast.sv
      gi_of(qid, feed_i) → g_id / base_terms
    rtl/native_graph/integrate/a7ng_teacher_off_glue.sv  map_q(tok)
    rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv    map_q(tok)

MATERIALIZER
  a7ng_late_materialize.sv  — AFTER Top-K only (not scorer evidence)
  NO existing pre-score ID→record module
  U6 adds: a7ng_u6_record_lut.sv  (preloaded FPGA table, 20-bit exact ID)

SCORER
  rtl/native_graph/scorer/a7ng_scorer_lane.sv     production 2-stage PE
  rtl/native_graph/scorer/a7ng_scorer_array.sv    16-lane wrapper
  rtl/native_graph/scorer/a7ng_termgen_*.sv       TermGen cue path (not U6)

TOPK
  rtl/native_graph/topk/a7ng_topk.sv                 frozen bitonic; beats()
  rtl/native_graph/topk/a7ng_topk_stream_minheap.sv  production stream; copies beats()
  a7ng_topk_wavefront_*                             research rivals

COMPLETION
  walker q_done  — retrieval only
  heap ST_DRAIN last idx==K-1 — Top-K commit
  learned_prior_graph snap_valid — C9 graph (legacy)
```

## Tie-break (frozen, not invented)

From `a7ng_topk.sv` `beats()` / copied in `a7ng_topk_stream_minheap.sv`:

```text
valid first
then score greater
then id lesser
then lane lesser
```

## Overflow interface (existing, not invented)

`a7ng_sparse_dir_axi`: `q_overflow_o`, `n_trunc_o`, `n_dup_o`, `n_emit_o`

U6 must latch and export these. Not INTERFACE_EVIDENCE_GAP.

## Multiple owners?

In **current SoC graph** (`a7ng_learned_prior_graph`) the only candidate owner is synthetic `qid` tables. The AXI walker is **not** connected to that scorer/heap.

U6 production top will instantiate **only** `a7ng_sparse_dir_axi` as SOURCE. Legacy graph stays in-repo and in TB as a disconnected falsifier.

Classification for U6 top: **ONE candidate owner** (walker). Not MULTIPLE_CANDIDATE_OWNERS.
