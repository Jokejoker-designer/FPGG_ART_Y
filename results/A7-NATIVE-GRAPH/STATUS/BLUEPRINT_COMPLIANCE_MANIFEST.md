# Blueprint package — compliance manifest

**Package path:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/`  
**Source archive:** `NATIVE_AI_ARTY_A7_COMPLETE_BLUEPRINT.zip` (extracted in-repo)  
**Purpose:** Map each Masterplan file to feedback/SPEC relevance and compliance docs.  

---

## Authority stack (read order)

```text
1. LOOP_STATE.json
2. 00_CURRENT_AUTHORITY.md (evidence delta)
3. COMPLIANCE_INDEX.md
4. feedback.md + BRAM_WORKING_MEMORY_SPEC.md (design input)
5. 01–15 blueprint files (architecture)
```

---

## Core blueprint files

| File | Role | feedback sections | SPEC sections | Compliance doc |
|------|------|-------------------|---------------|----------------|
| `README.md` | entry | §1 order | §43 | COMPLIANCE_INDEX |
| `00_CURRENT_AUTHORITY.md` | evidence delta | §14–§15, §26 stale | §2, §45 | §22 reconciliation table |
| `01_SYSTEM_BLUEPRINT.md` | architecture | §1, §43 | §0–§3, §43 | RECONCILIATION §2 |
| `02_IMPLEMENTATION_ROADMAP.md` | milestones A/B/C | §22 R0–R11 | §41 | Part B/C updated 2026-08-22 |
| `03_MINESWEEPER_TRAINING_GAME.md` | curriculum | §18, R8 | §14–§22 training | FEEDBACK G-P4-03 |
| `04_HARDSTOPS.md` | law | §2.2, §42 | §42 | NON_TRANSFERABLE patterns |
| `05_PARALLEL_AGENT_ENGINE.md` | 16 lanes | §5–§7 | §11 | G-P1-* gap register |
| `06_KNOWLEDGE_GRAPH_AND_ATTENTION.md` | graph | §10, §16 | §6 DDR records | G-P2-02 |
| `07_TEACHER_AUDITOR_PROTOCOL.md` | teacher | §17–§18 | §15–§16 | G-P4-02 |
| `08_MEMORY_ARCHITECTURE.md` | DDR/BRAM | §9, §14 | §3–§10, §28 | BRAM_SPEC_COMPLIANCE |
| `09_LM06_LOWBIT_OPTIMIZATION.md` | LM quant | §15 | §4 (frozen) | 00_AUTHORITY §3 |
| `10_VALIDATION_AND_EVIDENCE.md` | evidence classes | §2 | §45 | PROJECT_COMPLETE |
| `11_RESOURCE_CAPACITY_THROUGHPUT.md` | throughput | §5, §9 | §27 | mig_board_r2, MIG-METRIC |
| `12_FAILURE_DECISION_TREE.md` | debug | §21 | §42 | golden verify pattern |
| `13_CURSOR_MASTER_PROMPT.md` | agent law | §24 | — | 15_CURSOR_BLUEPRINT_LOOP |
| `14_FINAL_ACCEPTANCE_CHECKLIST.md` | GOAL | §26 | §45 | COMPLIANCE_GAP_REGISTER §14 |
| `15_CURSOR_BLUEPRINT_LOOP.md` | loop | §22 | §44 WM-00 | compliance re-read pack |

---

## Supporting assets

| Path | Role |
|------|------|
| `contracts/*.schema.json` | NG-00 teacher/telemetry — aligned with feedback HLB |
| `configs/resource_assumptions.json` | planning — not board authority |
| `tools/capacity_estimator.py` | ENGINEERING_ESTIMATE only |
| `templates/EXPERIMENT_CLOSEOUT_TEMPLATE.md` | scientific gate template |
| `references/REFERENCES.md` | bibliography |

---

## Repo-root design inputs (not in zip folder)

| File | Masterplan link | Compliance |
|------|-----------------|------------|
| `feedback.md` | informs `02` order, `08`, `11` | FEEDBACK_MD_COMPLIANCE |
| `BRAM_WORKING_MEMORY_SPEC.md` | extends `08`, `09` | BRAM_SPEC_COMPLIANCE |
| `BRAM_RESET_RETRAIN_PLAN.md` | `03`, TRAIN-V2 | train_v2 harness |

---

## STATUS artifacts (compliance layer)

| File | Function |
|------|----------|
| `COMPLIANCE_INDEX.md` | navigation hub |
| `COMPLIANCE_GAP_REGISTER.md` | OPEN gaps by ID |
| `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` | executive map |
| `FEEDBACK_MD_COMPLIANCE.md` | feedback § matrix |
| `BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md` | SPEC § matrix |
| `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md` | SPEC §28 extension |
| `RECORD_SCHEMA_FREEZE_STATUS.md` | §12 / §6.4 status |
| `COMPLIANCE_OBJECTIVE_AUDIT.md` | objective completion checklist |

---

## When blueprint and evidence disagree

Follow `00_CURRENT_AUTHORITY.md` correction box and `COMPLIANCE_GAP_REGISTER` superseded table.  
**Never** edit feedback/SPEC body for execution state — update compliance matrices.
