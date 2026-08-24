# 17 — Masterplan Blueprint V2 (IO-Aware)

**Written:** 2026-08-23  
**Goal:** **Complete Masterplan Blueprint V2** — architecture + gate DAG + metrics doctrine, reconciled with evidence and IO-aware research.  
**Does not replace:** `LOOP_STATE.json` (live execution).  
**Supersedes for planning:** informal roadmap fragments; extends `16_MASTERPLAN_EXECUTION_PATH.md`.  
**Research input:** `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md`

---

## 1. Two goals (do not conflate)

| Goal | Meaning | Done when |
|------|---------|-----------|
| **Blueprint V2 complete** | IO-aware masterplan package: doctrine, gate DAG, iron-law metrics, research indexed, no stale contradictions vs evidence | Checklist §10 all PASS |
| **Native V1 program complete** | Every §14 box evidenced on silicon; human `NATIVE_V1_MINI_AI_BOARD_PASS` | `PROJECT_COMPLETE.md` |

This document drives **Blueprint V2**. It does **not** declare BOARD_PASS.

---

## 2. Architectural bet (V2 north star)

```text
IO-Aware Stateful Native AI
```

Not “FPGA Transformer” and not “FPGA graph database.”

```text
CAPACITY     → DDR (streams + sparse metadata)
WORKING SET  → BRAM (waves, tiles, activations, Top-K, update buffer)
HOT CONTROL  → FF/LUTRAM (query/context, owner, epoch, queues)
COMPUTE      → follows data (score cheap early, fetch expensive late)
LEARNING     → small local persistent state (NPU path — V1.x research)
LM           → frozen composer; does not store all knowledge
```

**Principle (from literature, not RTL):** optimize **bytes and lifetime** before MAC count. SOA is necessary, not sufficient.

---

## 3. Iron-law metrics (required on every optimization gate)

Wall-clock query time:

```text
T_query ≈ max(B_query / BW_eff, O_query / R_compute_eff) + L_control
```

Per-candidate roof:

```text
R_candidate ≤ min(R_PE, BW_eff / β_candidate)
```

**Gate law:** every optimization PR must state which term it improves (`B_query`, `BW_eff`, `R_compute_eff`, `L_control`). If none → do not implement.

**Anti-claims (forbidden without BENCH gate):**

- `832 B/query` ⇒ “23% faster”
- `16 candidates/emission` ⇒ “16 candidates/cycle sustained”
- SOA PASS ⇒ “DDR solved”

---

## 4. Memory doctrine V2 (extends `08_MEMORY_ARCHITECTURE.md`)

### 4.1 DDR taxonomy

```text
DDR_CAPACITY
├── DDR_STREAM     (LM weight tiles, compact candidate planes, coalesced writeback)
└── DDR_SPARSE     (survivor metadata, edges, relations, episodes)
```

### 4.2 BRAM working set

```text
BRAM_WS
├── staged descriptor wave
├── LM active tiles
├── activations (u_a — primary LM06 focus)
├── frontier + global Top-K
└── update buffer (NPU / local learn — future)
```

### 4.3 Peak BRAM (TinyEngine-style)

Do not sum modules blindly:

```text
M_peak = max_t Σ_i valid_i(t) × size_i
```

LM06 trace must deliver: birth, last-read, reuse distance, phase, dirty, recomputable, spill/recompute decision.

### 4.4 DDR arbitration

Prefer **phase ownership** over cycle-fair interleaving:

```text
GRAPH → DRAIN → OWNER_SWITCH → LM → DRAIN → GRAPH
```

Not `graph, lm, graph, lm` per cycle.

---

## 5. Benchmark layers (V2 evidence taxonomy)

| Layer | Measures | Example gates |
|-------|----------|---------------|
| **Transport micro** | AR/R conservation, useful bytes, burst efficiency, protocol checker | `ddr_cue_soa_00r_axi_liveness` |
| **Native kernel** | bytes/query, memory_wait, candidates/cycle, Top-K correctness | `ddr_cue_soa_bench_01`, `wf_global_topk_*` |
| **End-to-end AI** | query → retrieval → LM → FPGA token, quality + latency | `hs22_lm06_active_00`, `hs02_semantic` |

---

## 6. Gate DAG — human-approved order (V2)

### Phase A — IO correctness (CRITICAL — live)

```text
WF-GLOBAL-TOPK-00          [DONE_ENG]
DESCRIPTOR-CONTRACT-00       [DONE_ENG — 104b frozen]
ddr_cue_soa_00             [BLOCKED — transport FAIL]
ddr_cue_soa_00r_axi_liveness [OPEN — repair only]
```

**ONE UNKNOWN (unchanged):** 104-bit lawful descriptor in exactly **832 B / 64 candidates** without law change.

**STOP** after `00R` closeout — no scope creep.

### Phase B — Prove IO value

```text
DDR-CUE-SOA-BENCH-01
```

| Field | Value |
|-------|-------|
| Prerequisite | `ddr_cue_soa_00r_axi_liveness` PASS |
| ONE UNKNOWN | Does SOA reduce `B_query` and/or `memory_wait` vs AOS at same law? |
| Control | AOS 1024 B/query, same candidate set, same TermGen/scorer/Top-K |
| Metrics | bytes/query, r_beats, memory_wait cycles, candidates/cycle (sustained) |
| Evidence | MIG_XSIM + optional BOARD (human scope) |
| Forbidden | throughput claim without measured table |

### Phase C — IO-aware graph (late materialize)

```text
GRAPH-LATE-MATERIALIZE-00
```

| Field | Value |
|-------|-------|
| Prerequisite | Phase B PASS |
| ONE UNKNOWN | Can expensive edge/episode payload fetch move after global Top-K without law change? |
| Principle | SCORE CHEAP EARLY — FETCH EXPENSIVE LATE |
| Forbidden | TermGen retune, HIT_MAX change, host hints |

### Phase D — LM memory physics (parallel track)

```text
LM06-WM-TRACE-00  →  one WM candidate  →  P&R  →  lm06_wm_ladder (ceilings)
```

| Field | Value |
|-------|-------|
| ONE UNKNOWN | What is `M_peak` for `u_a` lifetime vs phase overlap? |
| Insight (TinyTL) | Activation memory may dominate; parameter count alone does not solve BRAM |
| Ladder | 96/64/48/32 = reporting ceilings; stop at first Pareto good rung |
| Forbidden | Blind cut to 32 without trace evidence |

### Phase E — Global memory ownership

```text
BRAM-OWNER-00
```

Phase FSM: `GRAPH → BLOCK_NEW → DRAIN → OWNER_SWITCH → LM` (+ reverse).  
Ship: `BRAM_OWNERSHIP_POST_ROUTE.md` (SPEC §28).

### Phase F — Real intelligence path

```text
HS22-LM06-ACTIVE-00  →  FPGA token from frozen LM-06
```

### Phase G — Exam

```text
HS-02 teacher-off semantic retrieval
```

### Research lane (not V1 critical path)

```text
NPU-V1-LAW-00        (pairwise margin, fixed η — doc + golden)
NAE-V1               (adaptive encoder — post HS-22)
W4 / LoRA / AWQ      (post Native V1 freeze)
HNSW                 (research-only per HS)
ENC-GEOM-DIAG-00     (encoder lane — no graph credit)
```

---

## 7. Frozen laws (V2 non-negotiable)

Unchanged from `04_HARDSTOPS.md` + descriptor freeze:

- HS-01 host boundary (no ΔW, winner, address, answer)
- TermGen / scorer / Top-K laws unless explicit new `law_id` gate
- 01R, 02M, LM-06 bitstreams frozen
- Stage-1 descriptor: `node_id(32) + node_cue(64) + learned_prior(8) = 104b`
- AI does not declare BOARD_PASS

---

## 8. Relationship to `16_MASTERPLAN_EXECUTION_PATH.md`

| Topic | `16_` | `17_` (this doc) |
|-------|-------|------------------|
| Gate order graph/LM/integration | **Authoritative baseline** | Same order + Phases A–G naming |
| IO-aware doctrine | Implicit | **Explicit** |
| Iron-law metrics | Partial (`11_`) | **Required per gate** |
| SOA ceiling (~1.23×) | Not stated | **Documented** |
| BENCH / late-materialize gates | Not named | **Named, queued after A** |
| NPU / LoRA ordering | Not in masterplan | **Research lane only** |

When `16_` and `17_` disagree on **execution**, `LOOP_STATE.json` wins. When `17_` adds gates, human dispatch or compliance index update required before OPEN.

---

## 9. Cursor / orchestrator rules (V2)

1. Read `LOOP_STATE.json` before every session.
2. One unknown per implementer gate.
3. Parent = orchestrator; RTL via Task subagents only.
4. PASS → verify trio → next OPEN item (unless `stop_after_closeout` on repair gate).
5. Research docs (`NATIVE_AI_IO_AWARE_*`) = **RESEARCH_INPUT**, not AUTHORITY.
6. Do not open Phase C before Phase B; do not open BRAM owner before WM trace.

---

## 10. Blueprint V2 completion checklist

Mark PASS only with file-backed evidence in `results/A7-NATIVE-GRAPH/STATUS/MASTERPLAN_BLUEPRINT_V2_STATUS.md`.

| # | Deliverable | Status |
|---|-------------|--------|
| V2-1 | This document (`17_`) published | **PASS** |
| V2-2 | IO research indexed in `COMPLIANCE_INDEX.md` | **PASS** |
| V2-3 | Iron-law gate template in `10_VALIDATION_AND_EVIDENCE.md` or STATUS template | **PASS** (`GATE_IRON_LAW_TEMPLATE.md`) |
| V2-4 | Phase A gates reconciled with LOOP_STATE (no stale WF/descriptor text) | **PASS** (`BLUEPRINT_V2_PHASE_A_RECONCILE.md`) |
| V2-5 | Phase B–G gate stubs in `02_IMPLEMENTATION_ROADMAP.md` Part C | **PASS** (C.1 + C.5) |
| V2-6 | `00_CURRENT_AUTHORITY.md` §pointer to `17_` | **PASS** (§10.2) |
| V2-7 | `MASTERPLAN_BLUEPRINT_V2_STATUS.md` audit PASS | **PASS** |
| V2-8 | No contradiction vs `14_FINAL_ACCEPTANCE_CHECKLIST.md` | **PASS** (`AUDIT_BLUEPRINT_V2_vs_SECTION14.md`) |

**Blueprint V2 complete** = V2-1 … V2-8 all PASS. **Status: COMPLETE (2026-08-23).**  
**Program complete** = separate (`PROJECT_COMPLETE.md`).

---

## 11. Immediate execution (live — not blueprint doc)

| Priority | Gate | Agent track |
|----------|------|-------------|
| **P0** | `ddr_cue_soa_00r_axi_liveness` | memory-arch |
| P1 | `ddr_cue_soa_bench_01` | memory-arch (after P0 PASS) |
| P2 | `LM06-WM-TRACE-00` | memory-arch (parallel, human re-open ladder) |
| P3 | `GRAPH-LATE-MATERIALIZE-00` | memory-arch + scientific |

---

## 12. References

| Source | Role |
|--------|------|
| `NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md` | RESEARCH_INPUT |
| `16_MASTERPLAN_EXECUTION_PATH.md` | Human-approved DAG baseline |
| `HUMAN_APPROVAL_20260822.md` | Bottleneck resolution authority |
| `DESCRIPTOR_CONTRACT_FREEZE.md` | 104b stage-1 law |
| `DDR_CUE_SOA_00R_AXI_LIVENESS.md` | Live repair gate spec |
| Roofline / Eyeriss / FlashAttention / TinyTL / MCUNet | Design precedent — not evidence |
