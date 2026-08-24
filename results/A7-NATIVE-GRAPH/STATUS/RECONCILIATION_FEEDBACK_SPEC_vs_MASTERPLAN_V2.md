# RECONCILIATION — feedback.md + BRAM_WORKING_MEMORY_SPEC vs Masterplan V2 + evidence

**Created:** 2026-08-22  
**Authority:** Parent orchestrator synthesis (documentation only)  
**Inputs read:**

- `feedback.md` (2026-08-21 audit)
- `BRAM_WORKING_MEMORY_SPEC.md` (`A7-NATIVE-BRAM-WM-SPEC-v1`)
- `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` (Masterplan V2, esp. `00_CURRENT_AUTHORITY.md`, `08`, `14`)
- `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json`
- Audited closeouts through `mig_board_r2`, `ddr_wavefront_00`, `lm06_wm_00`
- `EXT-REPO-STUDY-ESP32-PLE-00` (methodology only)

**Authority order (unchanged):**

```text
1. Native AI raw evidence
2. frozen contracts
3. LOOP_STATE.json
4. audited closeouts
5. Master Blueprint V2
6. feedback.md + BRAM_WORKING_MEMORY_SPEC.md (design input — not execution override)
7. external research
```

**When feedback/SPEC conflicts with measured evidence or Masterplan V2 corrections:**
**Masterplan V2 + evidence win.** Conflicts are listed in §6, not silently reconciled.

---

## 1. Executive alignment

| feedback.md §1 verdict (2026-08-21) | Current state (2026-08-22) |
|-----------------------------------|----------------------------|
| Do not full-integrate yet | **Still true** — `full_integration` BLOCKED |
| Bottleneck = correctness + dataflow + DDR locality, then BRAM | **Partially advanced** — correctness gates DONE_ENG; DDR delivery measured; BRAM integration OPEN |
| Development order must not reverse | **Honored** in LOOP_STATE queue ordering |

| feedback.md §26 summary (stale) | Updated reading |
|---------------------------------|-----------------|
| NEXT = CORRECTNESS_REPAIR_PASS | **Superseded** — NG-02R-TOPK, NG-02R-FLOW, NG-06 epoch DONE_ENG |
| DDR = prototype only | **Advanced** — MIG-METRIC-00 XSim + mig_board_r2 silicon 16/16 grid |
| BRAM = hard future blocker | **Still true** — naive stack FALSIFIED; ownership FSM not proven on board |
| LM-06 not integrated | **Still true** for §14 HS-02 semantic chain |

---

## 2. feedback.md roadmap R0–R11 → Native evidence map

| feedback R-stage | Requirement | Native gate / artifact | Status | Evidence class |
|------------------|-------------|------------------------|--------|----------------|
| **R0** Audit freeze | Record findings without rewriting frozen evidence | `results/A7-NATIVE-GRAPH/**`, `00_CURRENT_AUTHORITY.md` | **DONE** | CHECKLIST_MAP |
| **R1** Correctness | True global Top-8, lossless flow, epochs, stale reject | `ng02r_topk`, `ng02r_flow`, `ng06_epoch`, `ng04_stale_event` | **DONE_ENG** | XSIM |
| **R2** Real parallel dispatch | 4/8/16-way, utilization measured | `ng06_wide_dispatch` | **DONE_ENG** (OOC LUT limit noted) | XSIM+OOC |
| **R3** TermGen | Full candidate features | `termgen` | **DONE_ENG** | XSIM+OOC |
| **R4** DDR feeding | burst, prefetch, double buffer, multi-outstanding | `mig_metric_00`, `mig_board_r2`, `ddr_feed`, `ddr_wavefront_00` | **DONE_ENG** (wavefront PASS_NARROW) | MIG_XSIM + BOARD_MIG + XSIM |
| **R5** Frontier shootout | bucket vs exact vs two-level | `frontier_shootout` | **DONE_ENG** — B_systolic winner | XSIM+OOC |
| **R6** Shared-memory integration | MIG + shared scratch + ownership, BRAM≤device, WNS≥0 | `integrate_fit` PASS_NARROW; `BRAM_OWNERSHIP_POST_ROUTE.md` PARTIAL | **PARTIAL** — proxy cut only, not Native V1 ship config | POST_ROUTE_SOC |
| **R7** Native query/attention | Remove hardcoded scaffolding | `ng09` intent XSim | **PROTOTYPE** — not §14 teacher-off semantic | XSIM |
| **R8** Real Kidi teacher-off | Blind native retrieval | `ng08`, `hs02_semantic` | **LIMIT** — not full HS-02 | BOARD_UART_LIMIT |
| **R9** Active LM-06 integration | retrieval → evidence → LM-06 → FPGA token | `hs02_lm_path`, `lm06_*` soc cuts | **LIMIT** — path visibility, not semantic chain | BOARD_UART_PROBE |
| **R10** NTDE observability first | Diagnostics before control | `ng07` anchor | **RESEARCH** | XSIM |
| **R11** Scale ladder | 20→800k episodes | — | **NOT STARTED** | — |

**Reading:** feedback development order (§1) is **largely executed through R5** at engineering-archive level. R6–R11 remain the §14 gap. Do not treat R4 "complete" as "DDR cannot starve PEs" — `ddr_wavefront_00` measured sustained throughput **unchanged** vs control.

---

## 3. feedback.md priority sections (P0–P6) — item status

| § | Topic | feedback severity | Native response | Current |
|---|-------|-------------------|-----------------|---------|
| **3** | Exact Top-K | P0 | NG-02R-TOPK bitonic global Top-8 | **CLOSED** (XSim) |
| **4** | Lossless flow | P0 | NG-02R-FLOW backpressure | **CLOSED** (XSim) |
| **5** | Physical parallelism underfed | P1 | NG-06 wide + epoch; utilization measured | **PARTIAL** — best ~44% service rate; 80% gate open |
| **6** | Query/path ownership | P1 | NG-06 epoch DROP_STALE | **CLOSED** (XSim) |
| **7** | 16 lanes ≠ 16 search engines | P1 | TermGen + frontier | **PARTIAL** — TermGen DONE; full search engine N/A |
| **8** | HDC/VSA research | research | — | **PARKED** |
| **9** | DDR starves PE array | P2 | MIG grid + wavefront | **ADVANCED** — 16/16 silicon; stall_frac still high |
| **10** | Locality-aware graph layout | P2 | — | **OPEN** |
| **11** | Frontier shootout | P2 | FRONTIER-SHOOTOUT | **CLOSED** (XSim) |
| **12** | Schema freeze | P2 | mem_schema_v1 pytest+xsim | **PARTIAL** — repo-wide freeze QUEUED |
| **13** | Banks = cache prototypes | P2/P3 | MEM-01/02 DDR windows | **DONE** (XSim) |
| **14** | BRAM integration blocker | P3 | integrate_fit LIMIT; lm06_wm ladder BLOCKED | **OPEN** |
| **15** | LM-06 BRAM audit before quant | P3 | MEM-00 audit 132 tiles | **DONE** (POST_ROUTE) |
| **16** | Native attention | P4 | ng09 | **PROTOTYPE** |
| **17** | Teacher firewall HW | P4 | teacher_off PASS_NARROW stub | **LIMIT** |
| **18** | Kidi-20 stronger test | P4 | ng08 | **HARNESS** |
| **19** | Evidence packet ≠ LM integration | P5 | documented in audits | **ACKNOWLEDGED** |
| **20** | NTDE observability | P5/P6 | ng07 | **RESEARCH** |
| **21** | Low-cost PERFMON | P6 | perfmon gate | **DONE** (XSim) — not wired to MIG path |

---

## 4. BRAM_WORKING_MEMORY_SPEC — section compliance

| SPEC § | Topic | Requirement | Evidence | Status |
|--------|-------|-------------|----------|--------|
| **0–1** | BRAM = WM, DDR = persistent; HLB boundaries | Doctrine locked | `AUTHORITY_MEMORY_DOCTRINE.md`, HLB audits | **SUPPORTED** |
| **2** | Physical constraint 132+ > 135 | Naive stack falsified | `00_CURRENT_AUTHORITY.md` §4 | **FALSIFIED (naive)** |
| **3** | Memory hierarchy DDR/BRAM/LUTRAM | Same as Masterplan §5 | `08_MEMORY_ARCHITECTURE.md` | **ALREADY PRESENT** |
| **6.4** | One authoritative record schema | Node16/Edge32/Episode32 | `mem_schema_v1` | **PARTIAL** — golden round-trip QUEUED |
| **10** | Ping-pong telemetry | swap_count, fill/empty stalls | `ddr_wavefront_00`, `mig_metric_00` | **PARTIAL** — `swap_count` still missing on MIG path |
| **27** | Performance counters | bank conflict, cache hit, lane_busy | perfmon elsewhere; not MIG-unified | **PARTIAL** |
| **28** | BRAM ownership report | hierarchy/tiles/role/phase columns | `INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` | **PARTIAL** — integrate_fit cut; no router/FIFO |
| **29–30** | Phase arbitration FSM | GRAPH↔LM owner switch | `bram_owner_00` QUEUED/BLOCKED | **NOT PROVEN** |
| **45** | BRAM_WORKING_MEMORY_ARCH_PASS | 10 requirements | See CONFORMANCE §6 + updates below | **NOT PASS** |

### SPEC §45 update (post wavefront + lm06_wm)

| # | Requirement | Post-2026-08-22 status |
|---|-------------|----------------------|
| 1 | exact Top-K | NG-02R-TOPK **PASS** |
| 2 | no silent data loss | MIG-METRIC-00 + mig_board_r2 **PASS** |
| 3 | query/path scoped state | NG-06 epoch **PASS** (XSim) |
| 4 | persistent knowledge in DDR | LM-06 contract + MEM gates **OBSERVED** |
| 5 | bounded WM buffers | ddr_wavefront bounded ping-pong **PASS_NARROW** (XSim) |
| 6 | multi-lane access | ddr_wavefront 16-lane wave **PASS_NARROW**; sustained DDR throughput **not solved** |
| 7 | DDR/BRAM traffic measured | MIG + wavefront + board grid **MEASURED** |
| 8 | post-route timing | per-gate Vivado PASS_NARROW; not one SoC |
| 9 | ownership documented | PARTIAL report only |
| 10 | no HLB violation | HLB CLEAN on audited gates |

**SPEC §45 overall: NOT PASS** — multi-lane sustained delivery + ownership FSM + final cut report remain open.

---

## 5. Masterplan V2 corrections vs feedback/SPEC phrasing

| Forbidden / stale phrasing | Correct authority | Source |
|----------------------------|-------------------|--------|
| "Move 802,816 weights from BRAM to DDR" | Weights **already** DDR-resident | `00_CURRENT_AUTHORITY.md` #1 |
| "243/135 might fit with optimization" | Naive stack **FALSIFIED** measured | #2 |
| "MIG board 0.92 stall is trusted" | Pre-metric rows **QUARANTINED**; mig_board_r2 supersedes | #4 + CLOSEOUT |
| "16 lanes ⇒ 16 records/cycle from DDR" | Lane count ≠ delivery | #5 |
| "PE util ≥80% blocks DDR path" | **Not** hard gate for memory path | `AUTHORITY_MEMORY_DOCTRINE.md` |
| feedback §26 "DDR prototype only" | Silicon 16/16 grid exists — still delivery-bound | mig_board_r2 |

---

## 6. Documented conflicts (not reconciled)

| ID | feedback/SPEC says | Evidence / Masterplan says | Resolution |
|----|-------------------|---------------------------|------------|
| C-01 | Large vocab head must fit SRAM (`budget.py` analog in SPEC sizing) | LM-06 uses DDR + BRAM tiles | Masterplan wins — different hierarchy |
| C-02 | feedback §5: 80% lane util engineering gate | Best measured ~44% recs/cyc | Gate remains **open**; not a memory-path blocker per doctrine |
| C-03 | SPEC §28 forbids integration claim without full ownership report | integrate_fit PASS_NARROW exists | Narrow proxy ≠ §14 integration |
| C-04 | feedback R6 implies one-shot integration | Phase ownership + ladder required | `bram_owner_00` + `lm06_wm_ladder` BLOCKED |
| C-05 | EXT-REPO PLE table pattern | PLE not Native V1 | `FUTURE_RESEARCH_ONLY.md` |

---

## 7. feedback §9 / SPEC §10 — measurement grid (updated)

| Axis | feedback §9 required | mig_metric_00 (2 cells) | mig_board_r2 (16 cells) | ddr_wavefront_00 |
|------|---------------------|---------------------------|-------------------------|------------------|
| burst 1/4/8/16 | yes | partial | **COMPLETE** silicon | cue path (not full MIG grid) |
| outstanding 1/2/4/8 | yes | partial | **COMPLETE** silicon | — |
| graph degree 4/8/16 | yes | missing | missing (authority: needs graph path) | uniform bank dist only |
| per-run metric_clear | implied | **PASS** | **PASS** | **PASS** |
| swap_count | SPEC §10 | missing | missing | bounded ping-pong (no swap counter) |
| PE stall_frac | yes | measured | measured 16/16 | memory_wait_fraction |
| sustained throughput win | hoped | partial | high stall persists | **NOT improved** vs control |

---

## 8. Open QUEUED items from feedback/SPEC (LOOP_STATE authority)

| Queue id | feedback/SPEC source | Status | Notes |
|----------|---------------------|--------|-------|
| `record_schema_freeze` | feedback §12, SPEC §6.4 | QUEUED | mem_schema_v1 partial |
| `bram_ownership_report` | SPEC §28 | QUEUED | Draft: `BRAM_OWNERSHIP_REPORT_V1_DRAFT.md` |
| `lm06_wm_ladder` | SPEC §31–36, feedback §14 | BLOCKED | human re-open; Pareto not mandatory to 32 |
| `bram_owner_00` | SPEC §29–30 | BLOCKED | after ladder |
| `full_integration` | feedback R6, SPEC §45 | BLOCKED | requires ownership + §14 boxes |

**Merged / done since CONFORMANCE note:**

| id | Was | Now |
|----|-----|-----|
| `mig_sweep_full` | QUEUED | MERGED → `mig_board_r2` **DONE_ENG** |
| `mig_board` / `mig_board_r2` | BLOCKED/OPEN | **DONE_ENG** BOARD_MIG |
| `ddr_wavefront_00` | OPEN | **DONE_ENG** PASS_NARROW |
| `lm06_wm_00` | BLOCKED | **DONE_ENG** PASS_NARROW |

---

## 9. EXT-REPO-STUDY transferables (methodology only)

From `EXT-REPO-STUDY-ESP32-PLE-00` — reinforces feedback §9 and SPEC §3 without changing architecture:

| External lesson | feedback/SPEC alignment | Native status |
|-----------------|------------------------|---------------|
| Classify memory by access pattern | feedback §9 order; SPEC §3 | **ALREADY PRESENT** |
| bytes touched ≠ stored capacity | feedback §13; SPEC DDR capacity examples | **ALREADY PRESENT** |
| Separate seq vs random benchmarks | feedback §9 experiments | MIG seq grid done; random metadata **OPEN** |
| Golden on deployed representation | feedback §3–4 correctness culture | lm06_wm_00 exemplar |
| Core-matched ablation | feedback scientific discipline | blueprint loop method |

**Does not justify:** PLE for Native V1, ESP32 perf as Arty evidence, or skipping ownership FSM.

---

## 10. §14 checklist — feedback/SPEC driven gaps (summary)

Still **NOT EVIDENCED** for human `NATIVE_V1_MINI_AI_BOARD_PASS`:

- Integrated SoC post-route on **shipped** Native V1 cut (not proxy)
- Semantic teacher-off HS-02 on full query path
- LM-06 active composition with structured evidence → FPGA token
- 800k bytes/query / candidates/query ladder
- Full BRAM ownership on final configuration
- Board-class evidence for graph+LM concurrent path

See `PROJECT_COMPLETE.md` rematch — GOAL NOT EVIDENCED.

---

## 11. Recommended reading order for implementers

```text
1. docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md
2. results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json
3. results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md
4. THIS FILE (feedback/SPEC ↔ evidence map)
5. feedback.md + BRAM_WORKING_MEMORY_SPEC.md (design intent)
6. Gate-specific CLOSEOUT / AUDIT for the OPEN gate only
```

---

## 12. NEXT (orchestrator)

**STOP** per `LOOP_STATE.next = STOP` until human re-opens `lm06_wm_ladder` or next gate.

This reconciliation doc does **not** tick LOOP_STATE or open gates.

**Supersedes for status purposes:** §7–§8 of `CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` (stale mig_board BLOCKED / wavefront OPEN lines). MIG-METRIC-00 conformance sections 1–6 remain valid.

**Navigation:** `COMPLIANCE_INDEX.md` — full feedback/SPEC ↔ masterplan index.
