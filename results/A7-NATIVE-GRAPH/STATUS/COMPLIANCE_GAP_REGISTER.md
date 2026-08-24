# COMPLIANCE_GAP_REGISTER — feedback + SPEC open items

**Authority:** Tracks OPEN gaps between design-input audits and measured Native AI evidence.  
**Navigation:** `COMPLIANCE_INDEX.md`  
**Date:** 2026-08-22  

Each row cites **feedback** and/or **SPEC** source, current status, and evidence required to close.

---

## P0 — Correctness (feedback §3–§4)

| ID | Source | Requirement | Status | Evidence to close |
|----|--------|-------------|--------|-------------------|
| G-P0-01 | feedback §3 | Global Top-8 exact | **CLOSED** | NG-02R-TOPK XSim |
| G-P0-02 | feedback §4 | Lossless flow | **CLOSED** | NG-02R-FLOW XSim |

---

## P1 — Parallelism and ownership (feedback §5–§7)

| ID | Source | Requirement | Status | Evidence to close |
|----|--------|-------------|--------|-------------------|
| G-P1-01 | feedback §5 | Lane util ≥80% | **OPEN** | Measured util on target workload; best ~44% today |
| G-P1-02 | feedback §5 | wide 4/8/16 dispatch | **CLOSED** | NG-06R-WIDE |
| G-P1-03 | feedback §6 | query/path epochs | **CLOSED** | NG-06R-EPOCH |
| G-P1-04 | feedback §7 | complete search engines | **PARTIAL** | TermGen done; full engine path N/A |
| G-P1-05 | SPEC §11 | per-lane bank conflict counters | **OPEN** | `bank_conflict_count` on integrated path |

---

## P2 — DDR and schema (feedback §9–§12, SPEC §10)

| ID | Source | Requirement | Status | Evidence to close |
|----|--------|-------------|--------|-------------------|
| G-P2-01 | feedback §9 | burst×outstanding grid | **CLOSED** | mig_board_r2 16/16 silicon |
| G-P2-02 | feedback §9 | graph degree 4/8/16 axis | **OPEN** | Graph-path sweep (not feed-only) |
| G-P2-03 | feedback §9 | cache hit rate | **OPEN** | Hotset telemetry on integrated path |
| G-P2-04 | SPEC §10 | `swap_count` ping-pong | **OPEN** | Counter on MIG/wavefront RTL |
| G-P2-05 | feedback §12, SPEC §6.4 | record schema freeze repo-wide | **QUEUED** | `RECORD_SCHEMA_FREEZE_STATUS.md` — mem_schema_v1 DONE; RS-01..04 OPEN |
| G-P2-06 | feedback §11 | frontier shootout | **CLOSED** | FRONTIER-SHOOTOUT |

---

## P3 — BRAM integration (feedback §14–§15, SPEC §28–§30, §45)

| ID | Source | Requirement | Status | Evidence to close |
|----|--------|-------------|--------|-------------------|
| G-P3-01 | feedback §14 | phase-based BRAM reuse | **PARTIAL** | lm06_wm_00 XSim bit-exact; ladder BLOCKED |
| G-P3-02 | SPEC §31–36 | WM ladder Pareto 96/64/48/32 | **BLOCKED** | `lm06_wm_ladder` human re-open |
| G-P3-03 | SPEC §29–30 | owner FSM GRAPH↔LM | **BLOCKED** | `bram_owner_00` |
| G-P3-04 | SPEC §28 | ownership report complete | **QUEUED** | `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md` → post-route on ship cut |
| G-P3-05 | SPEC §45 | `BRAM_WORKING_MEMORY_ARCH_PASS` | **OPEN** | All 10 §45 rows on Native V1 config |
| G-P3-06 | feedback §15 | LM BRAM audit before quant | **CLOSED** | MEM-00 / LM06_Q0 |

---

## P4–P6 — Semantic path (feedback §16–§21)

| ID | Source | Requirement | Status | Evidence to close |
|----|--------|-------------|--------|-------------------|
| G-P4-01 | feedback §16 | native attention | **PROTOTYPE** | ng09 — not §14 semantic |
| G-P4-02 | feedback §17 | HW teacher firewall | **LIMIT** | teacher_off UART stub |
| G-P4-03 | feedback §18 | Kidi native retrieval | **LIMIT** | ng08 harness |
| G-P4-04 | feedback §19 | evidence ≠ LM compose | **ACK** | documented |
| G-P4-05 | feedback §20 | NTDE observability | **RESEARCH** | ng07 |
| G-P4-06 | feedback §21 | PERFMON on all paths | **PARTIAL** | perfmon module; MIG path incomplete |

---

## Roadmap R-stages (feedback §22)

| R | Status | Note |
|---|--------|------|
| R0–R5 | **DONE_ENG** (archive) | See RECONCILIATION §2 |
| R6 shared memory | **PARTIAL** | integrate_fit proxy only |
| R7–R11 | **OPEN/LIMIT** | §14 gaps |

---

## Masterplan §14 (human BOARD_PASS)

| Area | Status | Primary gap register IDs |
|------|--------|--------------------------|
| Hardware integrated SoC | OPEN | G-P3-04, G-P3-05 |
| Teacher-off semantic | OPEN | G-P4-02, G-P4-03 |
| LM-06 active path | LIMIT | feedback §19, R9 |
| Memory bytes/query 800k | NOT STARTED | feedback R11 |
| Parallelism util | OPEN | G-P1-01 |

---

## Superseded / closed by later evidence

| Historical claim | Superseded by |
|------------------|---------------|
| feedback §26 NEXT=CORRECTNESS_REPAIR | NG-02R gates DONE |
| mig_board pre-metric rows trusted | QUARANTINE + mig_board_r2 |
| `mig_sweep_full` separate gate | MERGED → mig_board_r2 |
| LM weights must move BRAM→DDR | **FALSIFIED** — already DDR (`00_CURRENT_AUTHORITY` #1) |

---

## Maintenance

When closing a gap: update this register, the relevant compliance matrix row, `LOOP_STATE.json`, and
`00_CURRENT_AUTHORITY.md` §20 if applicable.

**Does not dispatch gates.**
