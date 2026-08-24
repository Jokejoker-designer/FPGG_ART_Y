# Compliance index — feedback.md + BRAM_WORKING_MEMORY_SPEC + Masterplan V2

**Purpose:** Single navigation entry for reconciling design-input audits with the Native AI
Masterplan package and file-backed evidence.

**Masterplan package:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` (from `NATIVE_AI_ARTY_A7_COMPLETE_BLUEPRINT.zip`).

**Live execution:** `LOOP_STATE.json` — always read first.

---

## Authority order

```text
1. BOARD / POST_ROUTE / XSIM raw evidence
2. frozen contracts (docs/contracts/**, CONTRACT_FREEZE.md)
3. LOOP_STATE.json
4. audited closeouts (CLOSEOUT.md, AUDIT_*.md)
5. Masterplan V2 (docs/NATIVE_AI_ARTY_A7_BLUEPRINT/**)
6. feedback.md + BRAM_WORKING_MEMORY_SPEC.md (design input)
7. external research (e.g. EXT-REPO-STUDY-ESP32-PLE-00)
```

When (6) conflicts with (1–5): **evidence and Masterplan win** — document conflict, do not reconcile silently.

---

## Compliance documents (2026-08-22)

| File | Read when |
|------|-----------|
| [`COMPLIANCE_GAP_REGISTER.md`](COMPLIANCE_GAP_REGISTER.md) | Every OPEN item with feedback/SPEC ID |
| [`BRAM_OWNERSHIP_REPORT_V1_DRAFT.md`](BRAM_OWNERSHIP_REPORT_V1_DRAFT.md) | SPEC §28 router/FIFO gaps (draft) |
| [`RECORD_SCHEMA_FREEZE_STATUS.md`](RECORD_SCHEMA_FREEZE_STATUS.md) | feedback §12 / SPEC §6.4 vs mem_schema_v1 |
| [`BLUEPRINT_COMPLIANCE_MANIFEST.md`](BLUEPRINT_COMPLIANCE_MANIFEST.md) | Masterplan file ↔ feedback/SPEC map |
| [`COMPLIANCE_OBJECTIVE_AUDIT.md`](COMPLIANCE_OBJECTIVE_AUDIT.md) | Objective C1–C10 completion checklist |
| [`RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md`](RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md) | Executive map, R0–R11, queue status, conflicts |
| [`FEEDBACK_MD_COMPLIANCE.md`](FEEDBACK_MD_COMPLIANCE.md) | Tracing a `feedback.md` section |
| [`BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md`](BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md) | Tracing a SPEC § section |
| [`00_CURRENT_AUTHORITY.md`](../../docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md) §22 | Masterplan pointer table |
| [`CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md`](CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md) | MIG-METRIC-00 vs §9/§10/§12 (§1–6 still valid) |

### Bottleneck resolution review (2026-08-22)

| File | Read when |
|------|-----------|
| [`../BOTTLENECK-RESOLUTION-REVIEW-00/HUMAN_APPROVAL_20260822.md`](../BOTTLENECK-RESOLUTION-REVIEW-00/HUMAN_APPROVAL_20260822.md) | **Human-approved next gate + execution order** |
| [`../BOTTLENECK-RESOLUTION-REVIEW-00/FINAL_RECOMMENDATION.md`](../BOTTLENECK-RESOLUTION-REVIEW-00/FINAL_RECOMMENDATION.md) | Full verdict table |
| [`MASTERPLAN_FINISH_STATUS.md`](MASTERPLAN_FINISH_STATUS.md) | Masterplan package vs program OPEN |
| [`MASTERPLAN_BLUEPRINT_V2_STATUS.md`](MASTERPLAN_BLUEPRINT_V2_STATUS.md) | **Blueprint V2 (IO-Aware) completion tracker** |
| [`BLUEPRINT_V2_COMPLETE.md`](BLUEPRINT_V2_COMPLETE.md) | **Blueprint V2 package COMPLETE marker** |
| [`../../docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md`](../../docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md) | Human-approved gate DAG (baseline) |
| [`../../docs/NATIVE_AI_ARTY_A7_BLUEPRINT/17_MASTERPLAN_BLUEPRINT_V2_IO_AWARE.md`](../../docs/NATIVE_AI_ARTY_A7_BLUEPRINT/17_MASTERPLAN_BLUEPRINT_V2_IO_AWARE.md) | **Blueprint V2 IO-aware plan + Phases A–G** |
| [`GATE_IRON_LAW_TEMPLATE.md`](GATE_IRON_LAW_TEMPLATE.md) | Required metrics block per optimization gate |

### IO-aware research (RESEARCH_INPUT — not AUTHORITY)

| File | Read when |
|------|-----------|
| [`../DDR-CUE-SOA-00/NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md`](../DDR-CUE-SOA-00/NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md) | Roofline, SOA ceiling, BRAM lifetime, NPU/LoRA ordering |
| [`DDR_CUE_SOA_00R_AXI_LIVENESS.md`](DDR_CUE_SOA_00R_AXI_LIVENESS.md) | Live SOA AXI repair gate spec |
| [`../DDR-CUE-SOA-00/00R/ATTEMPT6_CS249R_DATAFLOW_PLAN.md`](../DDR-CUE-SOA-00/00R/ATTEMPT6_CS249R_DATAFLOW_PLAN.md) | Attempt 6 cs249r plane-stationary dataflow law |
| [`RESEARCH_NATIVE_AI_AUTHORITATIVE_DIRECTIONS_20260823.md`](RESEARCH_NATIVE_AI_AUTHORITATIVE_DIRECTIONS_20260823.md) | **Extended research** — ZipCPU, UG586, GNN surveys, SLM, Chameleon |
| [`MEMORY_ALTERNATIVES_AND_IP_CATALOG_20260823.md`](MEMORY_ALTERNATIVES_AND_IP_CATALOG_20260823.md) | **BRAM alternatives + Xilinx IP** for Arty A7 |

**Live execution:** `LOOP_STATE.next` — verify file; snapshot in `MASTERPLAN_BLUEPRINT_V2_STATUS.md` §C.

**Historical note:** rows below marked stale until next compliance pass.

**Next gate (2026-08-23):** `ddr_cue_soa_00r_axi_liveness` — attempt 6 FAIL (cs249r plane gates insufficient; prior-first persists). Attempt 7: clone ddr_wavefront_00 engine.

**Historical (superseded):** `RECONCILIATION.md` (2026-08-21), `AUTHORITY_FEEDBACK_INGEST.md` (2026-08-21 ingest).

---

## Source documents (repo root)

| Document | Role | Header banner |
|----------|------|---------------|
| `feedback.md` | Development order, P0–P6 priorities, R0–R11 roadmap | Points to compliance trio |
| `BRAM_WORKING_MEMORY_SPEC.md` | WM architecture, §45 acceptance | Points to SPEC compliance |

Do not edit feedback/SPEC body for execution state — update compliance matrices and `LOOP_STATE` instead.

---

## Current snapshot (copy — verify LOOP_STATE)

| Item | Status |
|------|--------|
| `LOOP_STATE.next` | `STOP` |
| Memory chain through `lm06_wm_00` | **CLOSED** (XSim PASS_NARROW) |
| `lm06_wm_ladder` | **BLOCKED** (human re-open) |
| `mig_board_r2` | **DONE_ENG** BOARD_MIG 16/16 |
| `ddr_wavefront_00` | **DONE_ENG** PASS_NARROW XSim |
| SPEC §45 ARCH_PASS | **NOT PASS** |
| feedback §26 NEXT | **STALE** — was CORRECTNESS_REPAIR |
| Native V1 BOARD_PASS | **NOT EVIDENCED** |

---

## Open QUEUED (feedback/SPEC driven)

| Queue id | SPEC / feedback source |
|----------|------------------------|
| `bram_ownership_report` | SPEC §28 | QUEUED — draft: `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md` |
| `record_schema_freeze` | feedback §12, SPEC §6.4 | QUEUED — `RECORD_SCHEMA_FREEZE_STATUS.md` |
| `lm06_wm_ladder` | SPEC §31–36, feedback §14 (BLOCKED) |
| `bram_owner_00` | SPEC §29–30 (BLOCKED) |
| `full_integration` | feedback R6, SPEC §45 (BLOCKED) |

---

## Maintenance rule

When a gate closes:

1. Update `LOOP_STATE.json` (orchestrator / human).
2. Update `00_CURRENT_AUTHORITY.md` §20 status table if milestone visible there.
3. Update relevant rows in compliance matrices (this folder).
4. Do **not** rewrite `feedback.md` / SPEC historical audit text except header banners.

---

## Related

- `AUTHORITY_MEMORY_DOCTRINE.md` — locked memory gate order
- `PROJECT_COMPLETE.md` — §14 rematch (GOAL NOT MET)
- `EXT-REPO-STUDY-ESP32-PLE-00/` — external methodology only
