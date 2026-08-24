# Authority ingest — feedback.md + BRAM_WORKING_MEMORY_SPEC.md

> **SUPERSEDED for live status** (2026-08-22). Use instead:
>
> | Document | Scope |
> |----------|-------|
> | `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` | Combined map + conflicts |
> | `FEEDBACK_MD_COMPLIANCE.md` | feedback.md §1–§26 |
> | `BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md` | SPEC §0–§45 |
> | `00_CURRENT_AUTHORITY.md` §22 | Masterplan pointer |
>
> Retained below as **historical ingest snapshot** (2026-08-21).

**Ingested:** 2026-08-21 (orchestrator STATUS only)  
**Sources (repo root):**
- `feedback.md` — Native Graph audit / revised roadmap
- `BRAM_WORKING_MEMORY_SPEC.md` — `A7-NATIVE-BRAM-WM-SPEC-v1` (DESIGN SPEC / NOT BOARD AUTHORITY)

## Binding order (do not reverse)

```text
CORRECTNESS → LOSSLESS DATAFLOW → MULTI-LANE UTIL → TERMGEN
→ DDR FEEDING → FRONTIER SHOOTOUT → SHARED BRAM/DDR
→ NATIVE QUERY → TEACHER-OFF → LM-06 ACTIVE → NTDE → 800k
```

`integrate_fit` is **not** the current next gate.

## Alignment with LOOP_STATE (STALE — see compliance trio)

| Feedback item | Status at 2026-08-22 |
|---------------|----------------------|
| P0 global Top-8 | **DONE_ENG** NG-02R-TOPK |
| P0 lossless flow | **DONE_ENG** NG-02R-FLOW |
| P1 wide dispatch | **DONE_ENG** ng06_wide_dispatch |
| P1 query/path epoch | **DONE_ENG** ng06_epoch |
| P1 TermGen | **DONE_ENG** termgen |
| P2 DDR burst/locality | **DONE_ENG** MIG + mig_board_r2 + ddr_wavefront |
| P2 frontier shootout | **DONE_ENG** frontier_shootout |
| P2 record schema freeze | **QUEUED** record_schema_freeze |
| P3 shared BRAM WM | **lm06_wm_00 DONE_ENG**; ladder BLOCKED |
| P3 u_a phase-share | **FALSIFIED** naive stack — phase FSM OPEN |
| PERFMON | **DONE_ENG** |

## Claim discipline (from feedback §2.2)

```text
FITS ≠ RUNS ≠ TRAINS ≠ CONVERGES ≠ USEFUL
16 instantiated lanes ≠ 16 busy lanes
score composition ≠ complete candidate scoring
EVIDENCE_PACKET_PASS ≠ LM06_ACTIVE_INTEGRATION_PASS
```

## BRAM WM (spec summary)

- DDR = long-term knowledge; BRAM = working memory (candidates/frontier/Top evidence/learning buffer).
- Preferred hypothesis: phase-share graph scratch ↔ LM scratch (new bit only; never overwrite frozen LM-06).
- First experiment: `A7-BRAM-WM-00` **DONE_ENG**.
- Acceptance: `BRAM_WORKING_MEMORY_ARCH_PASS` — **NOT PASS** (see SPEC compliance matrix).

## Correctness gate (updated)

**CORRECTNESS_REPAIR_PASS** objectives are **largely closed** at XSim (Top-K, flow, epoch).  
Forbidden without new law id: NTDE decision law, encoder learning law, LM-06 internals rewrite, 01R/02M frozen semantics, 800k scale claims, HNSW datapath, approximate pruning.
