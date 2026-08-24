# BRAM_WORKING_MEMORY_SPEC — compliance matrix vs Native evidence

**SPEC:** `BRAM_WORKING_MEMORY_SPEC.md` (`A7-NATIVE-BRAM-WM-SPEC-v1`, 2026-08-21)  
**Masterplan:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` (V2)  
**Live map:** `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md`  
**Date:** 2026-08-22  

**Rule:** SPEC is design input. Measured evidence + `00_CURRENT_AUTHORITY.md` win on conflicts.

Status key: **MET** | **PARTIAL** | **OPEN** | **N/A** | **FALSIFIED**

---

## §0–§2 Purpose, boundaries, physical constraint

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 0 | BRAM = WM; DDR = persistent | **MET** | `08_MEMORY_ARCHITECTURE.md` §2; `AUTHORITY_MEMORY_DOCTRINE.md` |
| 1 | HLB boundaries (host must not grad/winner/answer) | **MET** (audited gates) | HLB audits; not universal silicon |
| 2 | LM-06 132 + encoder naive overflow | **FALSIFIED (naive)** | 243/135 measured; co-fit proxy 132 max |

---

## §3–§6 Memory hierarchy and DDR records

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 3 | DDR/BRAM/LUTRAM hierarchy | **MET** | Masterplan §5; matches SPEC diagram |
| 4 | BRAM semantic regions (query, candidate, score, frontier, Top-K, updates) | **PARTIAL** | NG-03/06/WM-00 prototypes; not integrated SoC |
| 5.1–5.6 | Logical BRAM region sizing | **OPEN** | Design targets; not post-route on ship config |
| 6.1–6.3 | NodeRecordV1 / EdgeRecordV1 / EpisodeRecordV1 | **PARTIAL** | `mem_schema_v1` XSim+pytest; repo-wide freeze QUEUED |
| 6.4 | One authoritative stride, no magic offsets | **PARTIAL** | 16 B stride on MIG path; `record_schema_freeze` QUEUED |

---

## §7–§11 Lifecycle, limits, banking

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 7 | WM lifecycle (reset, query scope, commit) | **PARTIAL** | NG-06 epoch; full phase FSM OPEN |
| 8 | Initial search limits (bounded candidates) | **MET** (doctrine) | feedback §6; avoid 800k scan |
| 9 | Physical BRAM architecture (shared pool) | **PARTIAL** | integrate_fit 130-tile proxy |
| 10 | Ping-pong telemetry | **PARTIAL** | empty/full stall present; **swap_count MISSING** on MIG path |
| 11 | BRAM banking for 16 agents | **PARTIAL** | ddr_wavefront 16-bank cue; per-bank peak not instrumented (MAJOR-2) |

---

## §12–§16 Top-K, NTDE, training architecture

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 12 | BRAM + exact Top-K | **MET** (XSim) | NG-02R-TOPK |
| 13 | BRAM + NTDE | **OPEN** | ng07 observability only |
| 14–16 | Training under WM model | **PARTIAL** | TRAIN-V2 harness; not WM-integrated retrain |

---

## §17–§25 Training protocol (T0–T7), dirty writeback

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 17–22 | Teacher role, curriculum, retrain protocol | **PARTIAL** | ng08 harness; not end-to-end silicon |
| 23 | Training hard stops | **MET** (policy) | contracts + HLB |
| 24 | BRAM training-mode behavior | **OPEN** | no integrated train+WM SoC |
| 25 | Dirty writeback policy | **OPEN** | no measured write path on MIG feed |

---

## §26–§27 Cache replacement and performance counters

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 26 | Cache replacement policy | **OPEN** | hotset prototypes only |
| 27 | Counter list (bank_conflict, cache_hit, lane_busy[i], …) | **PARTIAL** | perfmon module exists; **not unified** on MIG/wavefront path |

---

## §28 Required BRAM ownership report

| Required row | In `INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md`? | Status |
|--------------|-----------------------------------------------|--------|
| LM-06 | **YES** (u_w/u_a/u_snap) | PARTIAL |
| encoder | **YES** (A0.3 3 tiles) | PARTIAL |
| graph | **YES** (hotset cut) | PARTIAL |
| router | **NO** | OPEN |
| episodic memory | **YES** (DDR windows) | PARTIAL |
| FIFOs | **NO** | OPEN |
| MIG-related buffers | **YES** (0 BRAM cited) | PARTIAL |
| debug | **YES** (0 claimed) | PARTIAL |

**§28 verdict:** **PARTIAL** — integrate_fit cut + `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md` (router 56, 02M 52, FIFO TBD). Ship post-route enum still OPEN. SPEC forbids full integration claim.

---

## §29–§30 Phase arbitration and transition protocol

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 29 | Owner FSM (GRAPH/LM/MAINTENANCE); one writer/bank/cycle | **OPEN** | `bram_owner_00` BLOCKED in LOOP_STATE |
| 30 | GRAPH↔LM transition steps (drain, quiesce, commit) | **OPEN** | documented in SPEC + doctrine; not RTL proven |

---

## §31–§37 BRAM budgeting and recommended experiments

| § | Experiment | SPEC intent | Native gate | Status |
|---|------------|-------------|-------------|--------|
| 33 | First BRAM experiment (WM-00) | lossless WM prototype | `bram_wm_00` | **DONE_ENG** XSim |
| 34 | Second (timing OOC) | bankable timing | `wm00_timing` | **PASS_NARROW** |
| 35 | Third (DDR feed) | burst feed | `ddr_feed`, MIG gates | **DONE_ENG** |
| 36 | Fourth (integration cut) | ≤130 tiles | `integrate_fit` | **PASS_NARROW** proxy |
| 37 | Training under new law | TRAIN-V2 | `train_v2` | **DONE_HARNESS** |

---

## §38–§40 Training quality and relation vocabulary

| § | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 38 | Training quality gates | **PARTIAL** | harness only |
| 39–40 | Relation learning > token freq; bounded vocab | **PARTIAL** | ng05/contract; not 800k scale |

---

## §41 Recommended priority (P0–P3)

SPEC §41 ordering vs 2026-08-22 evidence:

| SPEC priority | Native status |
|---------------|---------------|
| P0 Top-K | **CLOSED** NG-02R-TOPK |
| P0 lossless flow | **CLOSED** NG-02R-FLOW |
| P1 wide dispatch | **DONE_ENG** NG-06R-WIDE (util open) |
| P1 epoch ownership | **CLOSED** NG-06R-EPOCH |
| P1 TermGen | **CLOSED** termgen |
| P2 DDR locality/burst | **ADVANCED** MIG + board 16/16; wavefront PASS_NARROW |
| P3 shared BRAM | **OPEN** — lm06_wm_00 bit-exact done; ladder/owner BLOCKED |

**Reading:** SPEC §41 agrees with feedback §1 — BRAM integration must not hide upstream defects; upstream P0–P2 largely closed at XSim/board-measurement level; **P3 remains the live blocker**.

---

## §42 Hard-stop summary

| Hard stop | Status |
|-----------|--------|
| BRAM > 135 naive stack | **FALSIFIED** — measured |
| dual ownership one bank | **NOT PROVEN** — FSM not implemented |
| silent candidate overwrite | **MET** on audited paths (MIG, Top-K, flow) |
| dirty state lost without policy | **OPEN** |
| persistent graph only in volatile WM | **MET** (doctrine) |
| host computes update | **MET** (HLB on audited gates) |
| teacher during blind inference | **LIMIT** — stub only |
| high score == semantic truth | **MET** (documented FALSE) |

---

## §43 Final target architecture

**ALREADY PRESENT** in `01_SYSTEM_BLUEPRINT.md` and `08_MEMORY_ARCHITECTURE.md`. SPEC diagram matches Masterplan intent. **Not evidenced** as one integrated post-route SoC.

---

## §44 Next branch A7-BRAM-WM-00

**SUPERSEDED by execution:** `BRAM-WM-00` DONE_ENG. SPEC "do not integrate LM-06 in WM-00" honored. Next per doctrine: `lm06_wm_ladder` (BLOCKED) → `bram_owner_00`.

---

## §45 `BRAM_WORKING_MEMORY_ARCH_PASS` — requirement checklist

| # | Requirement | Status | Primary evidence |
|---|-------------|--------|------------------|
| 1 | exact Top-K | **MET** | NG-02R-TOPK |
| 2 | no silent data loss | **MET** | MIG-METRIC-00, mig_board_r2, flow gate |
| 3 | query/path scoped state | **MET** (XSim) | NG-06R-EPOCH |
| 4 | persistent knowledge in DDR | **MET** (contract) | LM-06 DDR weights; MEM-01/02 |
| 5 | WM buffers bounded | **PARTIAL** | ddr_wavefront bounded ping-pong XSim |
| 6 | multi-lane access demonstrated | **PARTIAL** | wavefront 16-lane wave; sustained DDR throughput not solved |
| 7 | DDR/BRAM traffic measured | **MET** | MIG grid + wavefront metrics |
| 8 | post-route timing PASS | **PARTIAL** | per-gate Vivado; not one Native V1 SoC |
| 9 | BRAM ownership documented | **PARTIAL** | §28 report incomplete |
| 10 | no Native AI boundary violation | **MET** (audited) | HLB CLEAN on closed gates |

**§45 overall: NOT PASS** (needs 5–6–8–9 on final ship configuration + board where required).

---

## SPEC §33 first-task scope vs BRAM-WM-00 audit

| SPEC WM-00 scope item | Delivered? |
|-----------------------|------------|
| 256 candidate entries | Verify in BRAM-WM-00 closeout |
| 64 frontier entries | Verify in archive |
| Top-8 exact evidence | NG-02R-TOPK separate |
| 32 pending updates | WM-00 scope |
| 16 PE interface | WM-00 / wavefront |
| synthetic DDR graph | WM-00 / ddr_feed |
| PERFMON counters | perfmon gate (not all on MIG path) |
| no LM-06 in WM-00 | **YES** |

---

## Conflicts (SPEC vs evidence — not reconciled)

| ID | SPEC says | Evidence says |
|----|-----------|---------------|
| S-01 | §44 recommends new branch `arch/bram-working-memory-v1` | Branch executed as `BRAM-WM-00` in A7-NATIVE-GRAPH — **superseded naming** |
| S-02 | §2 implies encoder+LM fills 135 | Naive 243/135 with 01R/02M — use **measured** compositions |
| S-03 | §28 complete before integration | Partial report exists — **integration claim still forbidden** |

---

## NEXT (documentation only)

1. Complete §28 on Native V1 ship cut — draft at `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md`; fill FIFO TBD via post-route enum  
2. Add `swap_count` to MIG/wavefront telemetry — feedback §9 / SPEC §10  
3. Human re-open `lm06_wm_ladder` before BRAM tile reduction experiments  
4. `bram_owner_00` after ladder winner  

**Does not tick LOOP_STATE.**
