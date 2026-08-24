# GLOBAL_TOPK_REVIEW — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Reviewer role:** a7-integration-hlb-reviewer (via `a7-hlb-auditor`)

---

## 1. Carried risk (LOOP_STATE `lm06_wm_00.carried_risk_r1`)

**FACT:** `a7ng_ddr_wavefront_top` applies `a7ng_topk #(.N(16),.K(8))` **per wave** with **no cross-wave accumulator** `G_t`.

Safe in `ddr_wavefront_00` only because sequential `node_id` makes partition fixed. **Not safe** for general retrieval.

---

## 2. NG-02R vs integrated wavefront

| Layer | Proved | Scope |
|-------|--------|-------|
| NG-02R (`a7ng-topk-global-v1`) | Exact 16→8 within **one batch** | Standalone primitive |
| DDR-WAVEFRONT-00 | Reuses topk as black box; `topk_batches=4` | Delivery + per-wave selection |
| Global Top-K over full query | **NOT PROVED** | — |

**Q3 answer:** **WF-GLOBAL-TOPK-00 IS REQUIRED.** NG-02R does **not** close integrated wavefront global Top-K.

---

## 3. PROPOSAL A — recurrence

```text
G_0 = empty
G_(t+1) = TopK( G_t ∪ TopK(W_t) )
```

**Verdict: ACCEPT (AMEND)**

| Requirement | Status |
|-------------|--------|
| Reuse NG-02R comparator law (score desc, node_id asc, lane asc) | **YES** — 8+8=16→8 merge |
| New integration `law_id` | **REQUIRED** — e.g. `a7ng-topk-wavefront-global-v1` |
| Pad invalid slots in G_0 | **REQUIRED** — underfill contract |
| Stable lane assignment on merge | **REQUIRED** |
| Metadata fetch only after G_final | **REQUIRED** for DDR-CUE-SOA / HS-02 |

**REJECT:** Fixed bank=`node_id[3:0]` partition as production retrieval law.

### Comparator / tie law verification

NG-02R oracle: total order on `(score, node_id, lane_index)` with `valid_mask`. Merge of two Top-8 lists into 16→8 is **black-box exact** if same law — no new arithmetic.

---

## 4. WF-GLOBAL-TOPK-00 gate framing

**ONE UNKNOWN:** Does wavefront integration preserve the proven global Top-K law across waves?

| Prerequisite | Required? |
|--------------|-----------|
| `record_schema_freeze` | Soft — doc hygiene; **not** logic blocker |
| Frozen NG-02R primitive | **DONE_ENG** |
| Counterexample stream (non-sequential node_id) | **REQUIRED** in gate TB |

**Do not implement during this review.**

---

## 5. Interaction with late metadata (proposal §6)

**ACCEPT** ordering: global Top-K **must precede** late metadata fetch.

Fetching metadata on per-wave winners **invalidates** Recall@K and wastes DDR bandwidth (`metadata_fetch_ratio` undefined today).

---

## 6. Top-K in current wavefront evidence

Final wave winner `id=57, score=165` identical across traffic patterns — proves **delivery invariance**, not global correctness over arbitrary candidate streams.

---

## 7. Failure mode if skipped

```
Global rank-9 candidate in wave 2 never competes with wave-1 local Top-8 survivor
→ false retrieval evidence
→ HS-02 / §14 Knowledge graph Top-K box cannot close
```

Fix: Proposal A / WF-GLOBAL-TOPK-00.
