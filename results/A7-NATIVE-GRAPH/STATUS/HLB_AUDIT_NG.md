# HLB Audit — A7-NATIVE-GRAPH (NG-00..NG-03)

**Auditor:** a7-hlb-auditor  
**Date:** 2026-08-21  
**Scope:** `docs/contracts/native_graph/*`, `tests/native_graph/test_ng00_anti_leak.py`, `rtl/native_graph/**`, `rtl/board/arty_a7_ng0*.sv`, HS-01/02/03/04/05/14/15/21 in `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md`  
**Question:** If host code credited with FPGA work were deleted, would current NG claims still hold?

---

## Verdict

```text
HLB_PASS  (scoped: NG-00 contracts + NG-01..NG-03 engineering RTL)
HLB: CLEAN of CRITICAL active host→board learning leaks
```

**Not claimable under this audit:**

```text
HS-02 teacher-off persistence  →  BLOCKED (NG-05 learning path not built)
Native V1 / KIDI teacher-off   →  NOT IN SCOPE
```

No `python/` native_graph host, no UART lesson encoder, and no EVAL harness exist yet. There is therefore **no live host gradient / winner / address / answer path** to delete. Current NG-01..NG-03 claims (integer score compose, on-chip Top-K, FPGA-owned DDR address map) are self-contained in RTL/stim and survive host deletion.

---

## HLB line (auditor format)

`HLB: CLEAN` — 0 CRITICAL violations on the audited surface.  
2 MAJOR contract-hardening gaps (not active leaks).  
1 SCOPE block (teacher-off).

---

## Findings

### CRITICAL

None.

### MAJOR

```
[MAJOR] Lesson schema does not mechanically reject forbidden native fields
  file: docs/contracts/native_graph/teacher_lesson.schema.json
  what it computes: N/A — schema allows additional properties by default
  which claim it weakens: HS-01 / NG00-T2 “forbidden fields rejected”
  what FPGA/contract must do instead: set "additionalProperties": false and
    explicitly forbid gradient|delta_weight|winner|address|hash|next_token|final_answer
    (and BLIND_EXAM attention fields). Today rejection is pytest key-set only.
```

```
[MAJOR] Telemetry schema incomplete for HS-02 teacher-off proof fields
  file: docs/contracts/native_graph/telemetry.schema.json
  what it computes: exposes teacher_present + learn_enabled only
  which claim it weakens: HS-02 (needs teacher=0, external_LLM=0, learn=0, freeze=1)
  what FPGA/contract must do instead: add freeze_enabled and external_llm_present
    (or equivalent) before any teacher-off / KIDI closeout.
```

### SCOPE / NOT PASS (expected)

```
[SCOPE] Teacher-off persistence cannot PASS
  reason: NG-05 on-chip learning / weight-write path not present in pipeline
          (pipeline.json ends at NG-03 + HITL). No learn=0/freeze=1 board proof,
          no write-counter telemetry under EVAL, no held-out wording corpus gate.
  action: re-run a7-hlb-auditor when NG-05 + UART host exist; do not promote
          Native V1 on this HLB_PASS alone.
```

### WATCH (not violations yet)

| Item | Why watch |
|------|-----------|
| `score_terms_t` inputs on scorer lane | Today LFSR/board stim. If a future host sends entity/intent/context terms precomputed, that is HS-04 attention leakage. |
| `supervision.rank` in lesson schema | Allowed as label SUPERVISION only. Must never become “winning address / way” wiring. |
| `a7ng_bram_hotset` comment “host/MIG later supplies” fill | Fill path in NG-03 is FPGA AXI from `node_axi_addr`; keep host off raw DDR ARADDR. |
| Basys3 refs under `docs/native_graph/references/` | Contain host-grad / UART teacher patterns — research only; must not be ported as Arty host law. |

---

## Positive controls (what is correct)

| Control | Evidence | HS |
|---------|----------|----|
| Forbidden field list frozen | `teacher_lesson.schema.json` `forbidden_native_fields` enum + `CONTRACT_FREEZE.md` | HS-01 |
| Anti-leak pytest green | `pytest tests/native_graph/test_ng00_anti_leak.py -q` → **7 passed** | HS-01/04 |
| Top-K winner on FPGA | `rtl/native_graph/topk/a7ng_topk.sv` pairwise compare; tie → lower `node_id` | HS-01 |
| DDR address FPGA-owned | `a7ng_shard_fetch.sv` `node_axi_addr()` = `NG_DDR_NODE_BASE + nid<<4`; tops seed/query on-chip | HS-14 |
| No full-graph scan contract | single-beat AR (`arlen=0`); candidates/bytes counters | HS-13 |
| No host Python answer path | no `python/**` native_graph modules | HS-01/22 |
| Board tops have no UART payload | `arty_a7_ng01/02/03_top.sv` — SW/BTN/LFSR/self-seed only | HS-01 |
| No semantic ROM in NG RTL | no prompt→answer table in `rtl/native_graph` | HS-03 |

---

## Host→board payload surface (current)

No UART / AXI-lite host lesson port exists. Classification of **intended** contract surface (when host appears):

| Field | Source | Classification |
|-------|--------|----------------|
| `lesson_id` | host | TOKENIZE / logging |
| `phase` TRAIN\|AUDIT\|BLIND_EXAM | host | SUPERVISION / mode flag |
| `query` | host | TOKENIZE (text/tokens) |
| `source_ids[]` | host | SUPERVISION (curriculum ids) |
| `supervision[].item_id` | host | SUPERVISION (label id — not DDR addr) |
| `supervision[].reward` (−3…+3) | host | SUPERVISION |
| `supervision[].relation` | host | SUPERVISION |
| `supervision[].rank` | host | SUPERVISION (WATCH) |
| `gradient` / `delta_weight` | host | **FORBIDDEN** |
| `winner` / `address` / `hash` | host | **FORBIDDEN** |
| `next_token` / `final_answer` | host | **FORBIDDEN** |
| BLIND: `entity`/`intent`/`context`/`candidate_ranking`/`relation_path` | host | **FORBIDDEN** |
| DDR `ARADDR` / BRAM way | FPGA | FPGA-owned (must stay) |
| Top-K id/score | FPGA | FPGA-owned |
| Telemetry counters / flags | FPGA→host | TELEMETRY-READ |
| Cosine / rank metrics from dumps | host | METRIC-EVAL-ONLY |

---

## Hard-stop checklist (this audit)

| HS | Status |
|----|--------|
| HS-01 Host learning boundary | **PASS (scoped)** — no live host leak; schema soft-reject = MAJOR gap |
| HS-02 Teacher-off proof | **NOT PASS** — NG-05 absent |
| HS-03 No semantic ROM | **PASS** on current RTL |
| HS-04 No attention leakage | **PASS (vacuous)** — no blind exam host path yet |
| HS-05 No graph pre-answering | **PASS (vacuous)** — no teacher graph write port |
| HS-14 DDR address authority | **PASS** — FPGA `node_axi_addr` / hotset stride |
| HS-15 Train/eval separation | **DOC ONLY** — NG00-T5 corpus split still pending human |
| HS-21 Parameter accounting | **PASS** — kept separate below; no episode+param sum found |

---

## Parameter accounting (never sum into one headline)

```text
P_LM              = 802816     (frozen LM family; not part of NG-01..03 claim)
P_encoder         = 9216       (EAM lane; not part of NG-01..03 claim)
P_total_trainable = 802816 + 9216   (LM+encoder only; NG graph trainable = 0 today)
P_NG_trainable    = 0          (no NG-05 weight/update law instantiated)
N_episodes        = 0 / N/A    (no episode memory learning path)
episode_storage   = N/A
index_storage     = N/A
NG_HOTSET_DEPTH   = 256        (cache lines — not parameters, not episodes)
```

Do not report “P + hotset + episodes” as model size.

---

## Re-audit triggers

1. Any host UART / Vitis app that builds NG lesson packets.  
2. Wiring of `score_terms_t` or `node_id` from host.  
3. NG-05 learning RTL + EVAL write counters.  
4. Schema change adding `additionalProperties: false` (should clear MAJOR #1).  
5. Any Native V1 / KIDI / teacher-off closeout claim.

---

## Summary for parent

Scoped **HLB_PASS** for NG-00..NG-03: no CRITICAL host learning boundary violations; Top-K and DDR addressing stay on FPGA; anti-leak tests 7/7 green. Teacher-off persistence is explicitly **not** passed (NG-05 not built). Harden lesson schema `additionalProperties` and telemetry freeze/LLM flags before host integration.
