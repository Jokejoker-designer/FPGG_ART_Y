# feedback.md — compliance matrix vs Native evidence

**Source:** `feedback.md` (2026-08-21 audit)  
**Masterplan:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/`  
**Cross-ref:** `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md`  
**Date:** 2026-08-22  

**Rule:** feedback is design audit input. `LOOP_STATE.json` + audited closeouts override §26 status summary.

---

## §1 Executive verdict — development order

| Order step | feedback requirement | Native status (2026-08-22) |
|------------|---------------------|----------------------------|
| CORRECTNESS | Top-K, flow, epochs | **DONE_ENG** (NG-02R-TOPK, FLOW, NG-06 epoch) |
| LOSSLESS DATAFLOW | backpressure | **DONE_ENG** |
| REAL MULTI-LANE | wide dispatch | **DONE_ENG** (utilization ~44% best; 80% open) |
| TERM GENERATION | TermGen | **DONE_ENG** |
| DDR FEEDING | burst/prefetch/multi-out | **DONE_ENG** (MIG + board 16/16 + wavefront) |
| FRONTIER / SEARCH | shootout | **DONE_ENG** B_systolic |
| SHARED BRAM / DDR | integration | **OPEN** — ownership FSM not proven |
| NATIVE QUERY / ATTENTION | learned cues | **PROTOTYPE** ng09 |
| TEACHER-OFF RETRIEVAL | blind exam | **LIMIT** |
| LM-06 ACTIVE | evidence → LM → token | **LIMIT** |
| NTDE | observability first | **RESEARCH** ng07 |
| 800k SCALE | ladder | **NOT STARTED** |

**Verdict:** Order **not reversed**. Full integration step **not reached**.

---

## §2 Evidence status

### §2.1 Supported (feedback list) — current

| feedback claim | Still true? | Update |
|----------------|-------------|--------|
| routed parallel scorer | yes | NG-01 POST_ROUTE |
| routed Top-K/frontier | yes | NG-02R-TOPK |
| DDR/hotset smoke | yes | extended to MIG + wavefront |
| Python contracts/tests | yes | ng00, mem_schema |
| modular worktrees | yes | A7-NATIVE-GRAPH lane |

### §2.2 Not yet supported — current

| feedback claim | Status |
|----------------|--------|
| 16 fully utilized physical agents | **OPEN** (~44% service rate) |
| 1.6G candidates/s | **NOT CLAIMED** |
| full Native AI integrated fit | **OPEN** |
| Kidi teacher-off native retrieval | **LIMIT** |
| LM-06 active final-answer composition | **LIMIT** |
| 800k episode scaling | **NOT STARTED** |
| NTDE improving semantic search | **NOT PROVEN** |

Distinctions FITS/RUNS/TRAINS/USEFUL and 16 lanes≠16 busy — **still mandatory**.

---

## §3–§4 P0 Correctness and flow

| § | Issue | Status | Evidence |
|---|-------|--------|----------|
| 3 | Pair-winner ≠ global Top-8 | **CLOSED** | NG-02R-TOPK |
| 4 | Lossless ready/valid | **CLOSED** | NG-02R-FLOW |

---

## §5 P1 Physical parallelism underfed

| Requirement | Status | Note |
|-------------|--------|------|
| wide dispatch 4/8/16 | **DONE_ENG** | NG-06R-WIDE |
| lane utilization measured | **PARTIAL** | perfmon; MIG path aggregate only |
| ≥80% util gate | **OPEN** | feedback: "not scientific law"; doctrine: not DDR-path blocker |

---

## §6–§7 P1 Ownership and lane completeness

| § | Requirement | Status |
|---|-------------|--------|
| 6 | query/path epochs, stale reject | **CLOSED** NG-06R-EPOCH |
| 7 | 16 complete search engines | **PARTIAL** — TermGen done; full engine N/A |

---

## §8 HDC/VSA research

**PARKED** — not on Native V1 critical path.

---

## §9 P2 DDR starves PE array

| Experiment axis | feedback | Native |
|-----------------|----------|--------|
| burst 1/4/8/16 | required | **DONE** silicon 16/16 |
| outstanding 1/2/4/8 | required | **DONE** silicon |
| degree 4/8/16 | required | **MISSING** (graph path) |
| PE stall / util | required | **MEASURED** — stall_frac still high |
| sustained throughput win | hoped | **NOT** — ddr_wavefront unchanged vs control |

---

## §10–§11 P2 Locality and frontier

| § | Status | Evidence |
|---|--------|----------|
| 10 locality-aware layout | **OPEN** | — |
| 11 frontier shootout | **CLOSED** | FRONTIER-SHOOTOUT |

---

## §12 P2 Schema freeze

| Requirement | Status |
|-------------|--------|
| authoritative Node/Edge/Episode | **PARTIAL** mem_schema_v1 |
| golden round-trip | **QUEUED** record_schema_freeze |
| no magic strides repo-wide | **UNVERIFIED** |

---

## §13 P2/P3 Banks as prototypes

**DONE** at XSim — MEM-01/02 DDR windows. Not 800k board scale.

---

## §14–§15 P3 BRAM integration + LM audit

| § | feedback (2026-08-21) | Current |
|---|----------------------|---------|
| 14 | 135/135 naive blocker | **Still true** for naive stack; phase-share **OPEN** |
| 14 | phase-based reuse promising | **lm06_wm_00** bit-exact XSim; ladder BLOCKED |
| 15 | audit before quant | **DONE** MEM-00 132-tile ownership |

---

## §16–§20 P4–P6 Attention, teacher, Kidi, evidence, NTDE

| § | Status |
|---|--------|
| 16 native attention | PROTOTYPE |
| 17 teacher firewall HW | LIMIT stub |
| 18 Kidi stronger test | HARNESS/LIMIT |
| 19 evidence ≠ LM integration | ACKNOWLEDGED |
| 20 NTDE observability | RESEARCH |

---

## §21 PERFMON

**DONE_ENG** perfmon module. **PARTIAL** wiring on MIG feed path.

---

## §22 Revised roadmap R0–R11

See `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` §2 — full table.

**Summary:** R0–R5 **DONE_ENG** at archive level; R6 **PARTIAL**; R7–R11 **OPEN/LIMIT/NOT STARTED**.

---

## §23 Bottleneck priority

feedback priority vs 2026-08-22:

```text
1. correctness        → largely closed (XSim)
2. dataflow           → closed (XSim)
3. lane utilization   → open (~44%)
4. DDR locality       → measured; not solved
5. BRAM integration   → open (P3)
6. semantic teacher-off → open
7. LM active path     → limit
8. scale              → not started
```

---

## §24 Immediate Cursor task (stale)

feedback §24 recommended CORRECTNESS_REPAIR — **superseded** by completed NG-02R gates.  
Current stop: `LOOP_STATE.next = STOP` until human re-opens ladder.

---

## §25–§26 Final feedback and status summary

### §26 stale lines → corrected

| feedback §26 line | Corrected (2026-08-22) |
|-------------------|------------------------|
| NEXT = CORRECTNESS_REPAIR_PASS | Memory chain through lm06_wm_00 **CLOSED** (XSim); **STOP** |
| DDR = prototype | **ADVANCED** — 16/16 board grid + wavefront XSim |
| BRAM = hard blocker | **Still true** for integration |
| LM-06 not integrated | **Still true** semantic chain |
| FULL NATIVE AI not proven | **Still true** |

---

## feedback hard stops vs evidence

| Hard stop theme | Violated? |
|-----------------|-----------|
| global Top-8 wrong | **Fixed** |
| silent DROP on backpressure | **Fixed** MIG-METRIC-00 |
| host gradient/winner | **HLB CLEAN** on audited gates |
| full integration before DDR measure | **Honored** |
| increase PE before delivery measured | **Honored** |

---

## Masterplan alignment

| feedback concept | Blueprint doc |
|------------------|---------------|
| DDR remembers / BRAM thinks | `08_MEMORY_ARCHITECTURE.md`, SPEC §43 |
| development order | `02_IMPLEMENTATION_ROADMAP.md` Part C (updated) |
| §14 acceptance | `14_FINAL_ACCEPTANCE_CHECKLIST.md` |
| live queue | `LOOP_STATE.json` |

**Blueprint zip:** content lives in `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` (extracted authority package). No separate zip in repo; treat extracted docs as canonical.

---

## NOT DONE (objective still open)

- Full §14 human BOARD_PASS
- Semantic teacher-off on silicon
- LM-06 active answer path
- SPEC §45 / feedback R6 integration
- 800k scale ladder

This matrix is **documentation** — does not open gates.
