# §14 Final Acceptance Checklist — Evidence Audit

**Lane:** A7-NATIVE-GRAPH only (Digilent Arty A7-100T). Encoder H5 / EAM-03E is **out of scope** — do not glue.  
**Authority:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md`, `04_HARDSTOPS.md`  
**Evidence roots:** `results/A7-NATIVE-GRAPH/`, `docs/contracts/native_graph/`, `tests/native_graph/`, `rtl/native_graph/`  
**Auditor:** a7-evidence-auditor  
**Date:** 2026-08-21  
**Verdict class:** engineering status only — **AI does not declare `BOARD_PASS` or `NATIVE_V1_MINI_AI_BOARD_PASS`.**

---

## AUDIT: 3 FINDINGS

```
[MAJOR] Silicon smoke lacks archived program log
  where     : results/A7-NATIVE-GRAPH/NG-02|NG-03 closeouts; STATUS/RECONCILIATION.md
  claim      : "JTAG programmed" / "programmed via xsdb" as EVIDENCE
  evidence   : no xsdb/program/UART/JTAG artifact under results/A7-NATIVE-GRAPH/; only closeout prose
  why it matters: reader may treat silicon as proven when only impl+XSim artifacts exist
  fix        : archive xsdb transcript + LED/readback log, or downgrade claim to ENGINEERING_INFERENCE

[MAJOR] DDR_MAP vs closeout disagree on MIG bit
  where     : results/A7-NATIVE-GRAPH/NG-03/DDR_MAP.md:23 vs NG-03/closeout.md:14-16
  claim      : DDR_MAP says "MIG board bit | pending"; closeout says bit+SHA+xsdb smoke
  evidence   : build/out/arty_a7_ng03.bit EXISTS; SHA256 matches SHA256.txt / manifest
                (6D4CC18015EE338EC37B928DF6CEFA4444A913B5B34703345D78A7C64E0406A4)
  why it matters: stale "pending" line undercuts map authority; silicon still unlogged
  fix        : rewrite DDR_MAP evidence table to IMPLEMENTED (bit+SHA) vs BOARD (needs log)

[MINOR] Hotset named BRAM but util BRAM=0
  where     : rtl/native_graph/memory/a7ng_bram_hotset.sv; NG-03 util BRAM Tile = 0
  claim      : "BRAM hotset" / checklist "BRAM used as bounded hotset"
  evidence   : module uses logic arrays (distributed/inferred); post-route BRAM=0
  why it matters: resource honesty (HS-11) and checklist wording diverge
  fix        : rename to hotset/cache or force RAMB inference and re-measure
```

**Goal is NOT complete.** Native V1 remaining work estimate: **~80–85%** (NG-00..NG-03 scaffolding only; NG-04..NG-09, MEM/INT/LM compose, teacher-off exam, and integrated bit all open). Checklist item completion ≈ **~15%** if PARTIAL counts at half weight.

Encoder lane note (non-blocking here): `MUST_READ_UNBLOCK_H5` still owns ungated DIFF twin — **not** a graph §14 substitute.

---

## Headline numbers re-derived (not trusted from prose alone)

| Artifact | Claimed | Re-check |
|----------|---------|----------|
| NG-01 WNS/TNS | +2.400 / 0 | `a7ng01_timing_route.rpt` Design Timing Summary: **2.400 / 0.000** |
| NG-02 WNS/TNS | +0.408 / 0 | `a7ng02_timing_route.rpt`: **0.408 / 0.000** |
| NG-03 WNS/TNS | +1.166 / 0 | `a7ng03_timing_route.rpt`: **1.166 / 0.000** |
| NG-03 LUT | 4345 | util: Slice LUTs **4345** / 63400 on `xc7a100tcsg324-1` |
| NG-01 bit SHA | A414…C7A1 | `Get-FileHash build/out/arty_a7_ng01_scorer.bit` **match** |
| NG-02 bit SHA | EF46…716C | `build/out/arty_a7_ng02.bit` **match** |
| NG-03 bit SHA | 6D4C…06A4 | `build/out/arty_a7_ng03.bit` **match** |
| NG-00 pytest | 7/7 | `pytest tests/native_graph/test_ng00_anti_leak.py -q` → **7 passed** |

---

## Status legend

| Mark | Meaning |
|------|---------|
| **PASS_EVIDENCE** | Artifact exists and supports the §14 item for *current* scope without overclaim |
| **PARTIAL** | Real progress / subsystem proof; Native V1 integrated requirement still open |
| **FAIL** | Present claim or artifact contradicts the checklist |
| **NOT_STARTED** | No meaningful artifact for this item |

---

## Hardware

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| H1 | Integrated design fits `xc7a100t` | **PARTIAL** | Device in util reports (`xc7a100tcsg324-1`) for NG-01/02/03. **Missing:** INT-00..02 integrated top (graph+LM-06) post-route fit. |
| H2 | WNS >= 0 | **PARTIAL** | NG-01/02/03 post-route WNS all >0 (re-derived above). **Missing:** integrated Native V1 timing. |
| H3 | TNS = 0 | **PARTIAL** | NG-01/02/03 TNS 0.000. **Missing:** integrated bit. |
| H4 | Bitstream SHA archived | **PARTIAL** | `NG-0{1,2,3}/SHA256.txt` + manifests; bits present under `build/out/`. **Missing:** frozen Native V1 integrated SHA. |
| H5 | DDR map archived | **PARTIAL** | `NG-03/DDR_MAP.md` (node base `0x0100_0000`, 16 B/record). Edge region TBD. Stale "bit pending" line (Finding #2). |
| H6 | Resource report archived | **PARTIAL** | `NG-0{1,2,3}/a7ng0*_utilization_route.rpt`. **Missing:** integrated util. |
| H7 | Physical PE count from RTL/report | **PASS_EVIDENCE** | `rtl/native_graph/pkg/a7ng_pkg.sv` `NG_LANES=16`; `a7ng_scorer_array.sv` `generate` → `u_lane` ×16. Util reports are flat (no hierarchical lane dump) — count is RTL-sourced, not util-instance counted. |

---

## Learning boundary

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| L1 | Host sends no gradients | **PARTIAL** | Schema forbids `gradient` (`teacher_lesson.schema.json`); pytest `test_rejects_host_learning_fields_in_packet`. **Missing:** FPGA host UART/protocol capture proving absence on wire. |
| L2 | Host sends no ΔW | **PARTIAL** | Schema `delta_weight` forbidden + same pytest. No board bus trace. |
| L3 | Host sends no winner/address/hash | **PARTIAL** | Schema + pytest; RTL `a7ng_shard_fetch.sv` computes `node_axi_addr` on FPGA (HS-14 intent). No end-to-end host/FPGA lesson log. |
| L4 | Teacher only supplies supervision during TRAIN | **PARTIAL** | Phase enum TRAIN/AUDIT/BLIND_EXAM; NG-00 closeout. **Missing:** curriculum corpus with train≠exam entity split (explicitly pending in NG-00). |
| L5 | Learned graph/episode state changes on FPGA | **NOT_STARTED** | No NG-05 local learning RTL/closeout; no episode write path proven. |

---

## Query attention

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| Q1 | Native derives entity anchor | **NOT_STARTED** | Roadmap NG-07; no RTL/results. |
| Q2 | Native derives intent/context cue | **NOT_STARTED** | NG-07. |
| Q3 | Same entity/different intent changes ranking | **NOT_STARTED** | NG-09. |
| Q4 | Teacher sends no attention hint in blind exam | **PARTIAL** | Pytest `test_blind_exam_rejects_attention_hints` + schema doctrine. **Missing:** live BLIND_EXAM run artifact. |

---

## Knowledge graph

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| K1 | Directed typed relations | **NOT_STARTED** | Lesson schema allows optional `relation` string; no graph edge store / typed walk evidence. |
| K2 | Contextual bomb/prune | **NOT_STARTED** | NG-04 not present under `results/A7-NATIVE-GRAPH/`. |
| K3 | Wrong path does not reset global knowledge | **NOT_STARTED** | NG-05/NG-06. |
| K4 | Top-K evidence includes path/relation structure | **PARTIAL** | NG-02 Top-K XSim + bit (`NG-02/`). Structure is score/id winners, not path/relation evidence packets. |

---

## Parallelism

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| P1 | Declared physical lanes truly concurrent | **PARTIAL** | 16 parallel `u_lane` instances in RTL (NG-01/02). No silicon cycle-accurate concurrency measurement. |
| P2 | Logical agent count reported separately | **PARTIAL** | Telemetry schema fields `physical_lanes_active` / `logical_agents_active`; `RESOURCE_BUDGET.md` separates them. No runtime telemetry dump from board. |
| P3 | Lane utilization measured | **NOT_STARTED** | No lane util counter log under results. |
| P4 | DDR stalls measured | **NOT_STARTED** | No stall telemetry artifact. |

---

## Memory

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| M1 | Persistent graph/episodes DDR-backed | **PARTIAL** | FPGA-owned node fetch + DDR map; **not** persistent episode graph or flush/reload proof (MEM-01). |
| M2 | BRAM used as bounded hotset/cache/frontier | **PARTIAL** | Hotset DEPTH=256 + frontier RTL exist; util **BRAM=0** (Finding #3). Frontier is NG-02 buckets, not BRAM-backed proof. |
| M3 | No hidden 800k full scan | **PARTIAL** | Design: single 16 B beat on miss (`a7ng_shard_fetch.sv`); XSim `bytes=32`, `cands=3` in NG-03 closeout. **Missing:** 800k-scale measurement. |
| M4 | 800k scale bytes/query and candidates/query | **NOT_STARTED** | SCALE ladder not executed; only micro XSim numbers. |

---

## Teacher-off

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| T1 | teacher=0 | **NOT_STARTED** | Telemetry may *represent* `teacher_present`; no blind exam run with flags archived. |
| T2 | external_LLM=0 | **NOT_STARTED** | Doctrine only (`04_HARDSTOPS` HS-02); no release proof packet. |
| T3 | learn=0 | **NOT_STARTED** | Same. |
| T4 | freeze=1 | **NOT_STARTED** | Same. |
| T5 | held-out wording | **NOT_STARTED** | NG-08; curriculum pending. |
| T6 | unrelated reject | **NOT_STARTED** | NG-08. |
| T7 | contradiction probe | **NOT_STARTED** | NG-08. |

---

## LM-06

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| LM1 | LM-06 active on FPGA response path | **NOT_STARTED** | INT-02; graph tops are standalone (`rtl/board/arty_a7_ng0*_top.sv`). Frozen LM-06 bit untouched (correct). |
| LM2 | Structured Native evidence is LM input context | **NOT_STARTED** | No compose path. |
| LM3 | Host does not generate final answer | **PARTIAL** | Schema forbids `final_answer` / `next_token`; no integrated LM output proof. |

---

## Reset/retrain

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| R1 | Forget/reset removes learned behavior | **NOT_STARTED** | Requires NG-05+ learning state. |
| R2 | Retrain different mapping → different behavior | **NOT_STARTED** | Same. |

---

## Claims

| # | Checklist item | Status | Evidence / missing |
|---|----------------|--------|--------------------|
| C1 | `P_LM = 802,816` reported separately | **PARTIAL** | `docs/native_graph/RESOURCE_BUDGET.md` states `P_LM = 802816`. No Native V1 claim sheet packing counts. |
| C2 | encoder parameters reported separately | **PARTIAL** | Budget/doctrine separates encoder; no Native V1 encoder param line in graph results (encoder lane separate — correct non-glue). |
| C3 | graph nodes/episodes not added to parameter count | **PARTIAL** | HS-21 + RESOURCE_BUDGET doctrine; no false summed claim found in NG closeouts. |
| C4 | no open-domain/LLM/human-level claim without evidence | **PASS_EVIDENCE** | NG-00..03 closeouts explicitly disclaim Native V1 / BOARD_PASS; manifests `board_pass: false`. |

---

## Final verdict (checklist footer)

| Item | Status |
|------|--------|
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **NOT_STARTED** — **forbidden for AI to declare.** Every required §14 box is not PASS_EVIDENCE. Human-only when all boxes pass. |

---

## Counts

| Status | Count |
|--------|------:|
| PASS_EVIDENCE | **2** |
| PARTIAL | **22** |
| FAIL | **0** |
| NOT_STARTED | **20** |
| **Total checklist rows** | **44** |

*(Footer verdict tracked separately; not in the 44.)*

---

## Prior-doc honesty (FALSE_OR_OVERCLAIM / scope)

| Doc | Assessment |
|-----|------------|
| `NG-0{0,1,2,3}/closeout.md` | Engineering scope mostly honest; silicon smoke class overstated without logs → treat as **ENGINEERING_INFERENCE**, not board EVIDENCE. |
| `STATUS/RECONCILIATION.md` | Correct that §14 is far from complete; “human BOARD_PASS only” after NG-03 is **FALSE_OR_OVERCLAIM** relative to §14 (NG-04..INT-02 still required). |
| `NG-03/DDR_MAP.md` | Stale “MIG board bit pending” while bit+SHA exist → **FALSE_OR_OVERCLAIM** / stale. |
| Manifests `board_pass: false` | Correct. |

---

## Provenance separation (HS-19)

| Class | What exists now |
|-------|-----------------|
| Reference / contract | schemas, pytest, RESOURCE_BUDGET |
| XSim | NG-01/02/03 markers in manifests/closeouts |
| Implemented (post-route) | timing+util+bit+SHA for NG-01/02/03 |
| Board | **not verified** in this audit (no archived program log) |
| Semantic / teacher-off | **absent** |

Do not average or promote XSim/impl to board.

---

## Frozen-artifact law (HS-20)

No evidence in this audit window that frozen `arty_a7_eam01r.bit`, `arty_a7_eam02m.bit`, `arty_a7_lm*.bit`, or A0.3 bits were overwritten. NG bits are separate (`arty_a7_ng0*.bit`).

---

## Next 3 required stages (after NG-03)

Per `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/02_IMPLEMENTATION_ROADMAP.md` (not optional glue to encoder):

1. **NG-04** — Minesweeper contextual pruning (bomb path-local; no permanent blacklist).  
2. **NG-05** — Local edge/node learning on FPGA (host cannot inject ΔW; enables reset/retrain §14).  
3. **NG-06** — Multi-agent shared frontier (16 physical lanes × logical contexts; no global reset on path fail).

Then NG-07 anchors → NG-08/09 Kidi exams → MEM/INT → LM-06 compose → human-only Native V1 closeout.

---

## NOT VERIFIED

- Actual JTAG programming / LED smoke (no transcript under `results/A7-NATIVE-GRAPH/`).  
- Hierarchical post-route instance count of 16 `u_lane` (RTL only).  
- Whether `keep_hierarchy` was applied in the Vivado runs that produced util reports.  
- Content of XSim waveform/logs beyond closeout markers (TB logs not archived in results tree).  
- Encoder / A0.3 silicon state (intentionally out of lane).  
- Whether `build/out/*.bit` files are immutable archives vs rebuildable workspace copies (SHA match today only).
