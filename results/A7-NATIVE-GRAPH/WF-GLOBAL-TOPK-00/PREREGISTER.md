# PREREGISTER — wf_global_topk_00

**Gate:** `wf_global_topk_00`
**Agent:** `a7-ng-topk-frontier`
**Archive:** `results/A7-NATIVE-GRAPH/WF-GLOBAL-TOPK-00/`
**Evidence_class:** `XSIM` — **not BOARD**
**Law:** `a7ng-topk-wavefront-global-v1` (integration); primitive `a7ng-topk-global-v1` **unchanged**
**Written:** before any RTL edit, any simulation, any number.

## Scientific frame

| Field | Statement |
|-------|-----------|
| **OBSERVATION** | `ddr_wavefront_00` applies per-wave `a7ng_topk` 16→8 with no `G_t`; `carried_risk_r1`; NG-02R proves batch primitive only. |
| **UNKNOWN** | Does wavefront integration preserve proven global Top-K law across waves via `G_(t+1)=TopK(G_t ∪ TopK(W_t))`? |
| **H_CANDIDATE** | Reuse `a7ng_topk` for 8+8→16→8 merge with integration `law_id` `a7ng-topk-wavefront-global-v1` yields exact global Top-K on counterexample streams. |
| **H_RIVAL** | Per-wave partition still wrong; or merge ordering differs from NG-02R law. |
| **FALSIFIER** | Counterexample where global rank-9 in wave 2 beats wave-1 local winner but per-wave path picks wrong survivor. |
| **UNIT** | one query = full candidate set across waves (not one clock cycle). |
| **CONTROL** | NG-02R comparator law (score desc, node_id asc, lane asc); frozen `ddr_wavefront` except global reducer hook. |

## Session law acknowledged

- ONE unknown. No BOARD_PASS. No SOA / HS-02. No ladder / `bram_owner_00`.
- Frozen/forbidden and **not touched**: NG-02R comparator ordering inside `a7ng_topk.sv`, 01R law, HIT_MAX, TermGen, 02M, LM-06, training, encoder, `mig.prj`.
- `a7ng_topk` core is instantiated **unmodified** as merge primitive.

## Architecture under test

```text
Per wave (unchanged):
  16 lanes → TermGen → scorer → a7ng_topk (16→8) = TopK(W_t)

New (this gate):
  G_0 = empty (all slots invalid-padded)
  G_(t+1) = TopK( G_t ∪ TopK(W_t) )   via a7ng_topk 16→8 on concatenated 8+8
  G_final exposed as query result (replaces per-wave-only final top)
```

**Merge lane map (fixed):** slots 0..7 = `G_t` (valid_mask from accumulator state); slots 8..15 = `TopK(W_t)` (valid_mask from wave scored count).

## Preregistered METRICS

| Metric | Definition |
|--------|------------|
| `counterexample_pass` | 1 iff global rank-9 from wave 2 enters `G_final` and displaces wave-1 8th; per-wave-only oracle **fails** same stream |
| `merge_count` | number of `G_(t+1)` updates per query |
| `global_topk_match` | `G_final` equals Python oracle over full multi-wave candidate set |
| `primitive_unchanged` | SHA256 of `a7ng_topk.sv` matches NG-02R closeout |

## FALSIFIER table (any fires ⇒ FAIL)

| # | Falsifier |
|---|-----------|
| F1 | Global rank-9+ candidate in wave 2 beats wave-1 local 8th but absent from `G_final` |
| F2 | Per-wave-only (last wave) matches `G_final` on counterexample stream (reducer not needed) |
| F3 | Merge uses different comparator order than NG-02R |
| F4 | `a7ng_topk.sv` comparator law edited |
| F5 | BOARD_PASS or silicon claim |

## Counterexample stream (preregistered)

**Unit TB** (`tb_a7ng_wf_global_topk.sv`) — non-sequential `node_id`:

| Wave | Content | Purpose |
|------|---------|---------|
| W1 | ids `0xA000`..`0xA00F`; top-8 scores 200..130 (step −10) | Local 8th = **130** |
| W2 | `0xDEADBEEF` score **135** + fillers | Rank-9 beats W1 8th; enters `G_final` |
| W2-only oracle | Last-wave top-8 | **must FAIL** |

**Integrated TB** (`tb_a7ng_wf_global_topk_integrated.sv`) — schema-locked DDR (`node_id` 0..31, `expected_node_beat`):

| Wave | Content | Purpose |
|------|---------|---------|
| W1 | `node_id` 0..15 | Local 8th = **10@161** |
| W2 | `node_id` 16..31 | Cross-wave merge displaces W1 8th from `G_final` |
| Per-wave-only | W2 local top-8 | **must FAIL** (8/8 differ from global) |

## CONTROL

NG-02R `tb_a7ng_topk.sv` counterexample `{100,99}` law unchanged. This gate adds **cross-wave** counterexample only.

## Declared non-gates

- No MIG/DDR traffic re-measurement (delivery path frozen).
- No synthesis / post-route / board.
- No metadata-fetch ordering (documented requirement for future SOA gate).

## PASS criterion

XSim log contains `A7NG_WF_GLOBAL_TOPK_XSIM_PASS` with counterexample PASS and per-wave-only FAIL documented.
