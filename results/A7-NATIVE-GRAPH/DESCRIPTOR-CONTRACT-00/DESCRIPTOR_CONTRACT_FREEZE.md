# DESCRIPTOR_CONTRACT — Stage-1 Field Freeze

**Gate:** `descriptor_contract_00`  
**Law ids:** `a7ng-termgen-v0`, `a7ng-scorer-v0`, `a7ng-mem-schema-v1` (delivery only)  
**Authority:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md` §3, human approval `BOTTLENECK-RESOLUTION-REVIEW-00/HUMAN_APPROVAL_20260822.md`  
**Date:** 2026-08-22  
**Evidence class:** LAW_AUDIT (RTL trace + golden oracle + CONTRACT_FREEZE) — **not** BOARD, **not** SOA RTL  
**Blocks:** `ddr_cue_soa_00` until cited here

---

## Verdict

```text
STAGE1_DESCRIPTOR_BITS = 104
STAGE1_DESCRIPTOR_FIELDS = node_id(32) + node_cue(64) + learned_prior(8)
STATUS = FROZEN
```

96-bit lower bound (`node_id` + `node_cue` only) is **insufficient** for lawful first-pass ranking under the frozen score law.

---

## ONE UNKNOWN (closed)

**Which per-candidate fields does lawful stage-1 scoring actually consume?**

**Answer:** exactly three per-candidate fields — `node_id`, `node_cue`, `learned_prior` — plus query-context cue bags that are **not** part of the per-candidate DDR descriptor.

---

## Frozen stage-1 descriptor (logical)

| Field | Width (bits) | Role | Source class |
|------:|-------------:|------|--------------|
| `node_id` | 32 | Candidate identity; Top-K tie-break (`node_id` asc) | PER-CANDIDATE MEMORY |
| `node_cue` | 64 | TermGen HDC bus; all four feature families XOR/ROTL against this cue | PER-CANDIDATE MEMORY |
| `learned_prior` | 8 (signed `term_t`) | Passthrough score term; added in scorer stage-2 | PER-CANDIDATE MEMORY |

**Total logical width:** **104 bits** (13 bytes packed; SOA may pad to beat alignment).

### Query-context (NOT in stage-1 descriptor)

Broadcast per query, not fetched per candidate:

| Field | Width | Class |
|------|------:|-------|
| `query_cue` | 64 | QUERY-CONTEXT |
| `relation_cue` | 64 | QUERY-CONTEXT |
| `intent_cue` | 64 | QUERY-CONTEXT |
| `context_cue` | 64 | QUERY-CONTEXT |
| `path_cue` | 64 | QUERY-CONTEXT |

### Computed on FPGA (NOT stored per candidate)

| Term | Derivation |
|------|------------|
| `entity_match` … `path_confidence` | TermGen stage-1 XOR/ROTL + stage-2 popcount (`a7ng-termgen-v0`) |
| `contradiction_penalty` | TermGen from `query_cue`, `node_cue`, `path_cue` |
| Final `score` | Scorer compose (`a7ng-scorer-v0`) |

---

## Explicitly NOT consumed at stage-1 (NodeRecordV1 tail)

| NodeRecordV1 field | Off | Bits | Stage-1? |
|------------------|----:|-----:|:--------:|
| `node_type` | 4 | 16 | **NO** |
| `topic_id` | 6 | 16 | **NO** |
| `confidence` | 12 | 16 | **NO** — not aliased to `learned_prior` |
| `degree_sat` | 14 | 8 | **NO** |
| `version` | 15 | 8 | **NO** |

Full **NodeRecordV1 = 128 bits (16 B)** remains the **delivery container** on the measured wavefront path; stage-1 **semantic** consumption is the **104-bit subset** above.

---

## Physical packing rules (frozen for SOA planning)

### `node_cue` 64-bit widen (delivery layer only)

TermGen law consumes **64-bit** `node_cue`. NodeRecordV1 stores **32-bit** `cue` at byte offset 8.

**Lawful widen ops** (pick one per `law_id`; default until SOA gate):

| Rule id | Widen | Used today |
|---------|-------|------------|
| `cue-replicate-v0` | `CUE64 = {CUE32, CUE32}` | `a7ng_ddr_wavefront_top.sv` |
| `cue-complement-v0` | `CUE64 = {CUE32, ~CUE32}` | `a7ng_wavefront_mig_top.sv` |

Widen is **delivery-layer** only. TermGen XOR formulas are unchanged.

### `learned_prior` source (per candidate)

| Source | Status |
|--------|--------|
| Separate `NG_DDR_PRIOR_BASE` table (1 B / node, FPGA-owned) | **LAWFUL** — `a7ng_pkg.sv` |
| Compact wave record bits `[103:96]` | **LAWFUL** — `a7ng_wavefront_mig_top.sv` |
| Top-level broadcast `learned_prior_i` | **WIRING ARTIFACT** — not law; ranking wrong when priors differ |
| NodeRecord `confidence` u16 | **FORBIDDEN alias** — different width/semantics |

---

## Score law (unchanged)

From `docs/native_graph/CONTRACT_FREEZE.md`:

```text
Score = EntityMatch + IntentMatch + RelationMatch
      + ContextMatch + PathConfidence + LearnedPrior
      - ContradictionPenalty
```

`LearnedPrior` is **not** optional for lawful ranking when per-node priors differ.

---

## Byte budget implication (64 candidates, stage-1 only)

| Layout | Bytes / cand | Bytes / query (N=64) | Notes |
|--------|-------------:|---------------------:|-------|
| Full NodeRecordV1 (measured) | 16 | 1024 | Current MIG wavefront |
| Frozen stage-1 logical | 13 (104 b) | 832 | Theoretical packed |
| SOA target floor | TBD in `ddr_cue_soa_00` | ≥832 | Must not drop lawful fields |

---

## Wiring artifacts (not law proof)

| Artifact | Location | Disposition |
|----------|----------|-------------|
| `{cue,cue}` replication | `a7ng_ddr_wavefront_top.sv:250` | Delivery widen only |
| Broadcast `learned_prior_i` | `a7ng_ddr_wavefront_top.sv:255` | **Invalid** for production ranking when priors differ |
| 8 B “compact cue only” | Various proposals | **REJECT** for semantic stage-1 — missing `node_id` and/or `learned_prior` |

---

## SHA256 anchors (audit day)

| Artifact | SHA256 |
|----------|--------|
| `rtl/native_graph/scorer/a7ng_termgen_lane.sv` | `DD637EDAC060D407F44E81C6DD83FE3995150B4CDD275EEF2820757F22DF5218` |
| `rtl/native_graph/scorer/a7ng_scorer_lane.sv` | `7C8ACFD29C378D9DD8851AE7F646CBEEB0BADC287DA2A1D9931F8C6B3256ECB6` |
| `rtl/native_graph/pkg/a7ng_pkg.sv` | `267E5CF1F489E2926645D7914E28727264E18A1CE037CC175CAC7E8FA045959B` |
| `docs/native_graph/CONTRACT_FREEZE.md` | `214C2FE534D18095D128D215CFAC1B709DECD75485352DD73E073B0F329D51E5` |
| `results/A7-NATIVE-GRAPH/TERMGEN/golden_termgen.json` | `7BBE92AE…CF8BE0` (TERMGEN archive) |

---

## Downstream gates

| Gate | Prerequisite met |
|------|------------------|
| `ddr_cue_soa_00` | **YES** — 104-bit field set frozen; SOA may optimize fetch layout |
| `record_schema_freeze` | Parallel — NodeRecordV1 container unchanged; optional prior plane split documented here |

**No SOA RTL in this gate.** **No BOARD_PASS.**
