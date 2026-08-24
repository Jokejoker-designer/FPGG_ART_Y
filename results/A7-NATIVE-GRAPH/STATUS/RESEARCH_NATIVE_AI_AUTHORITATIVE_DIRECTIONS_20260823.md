# RESEARCH_INPUT — Authoritative directions for Native AI (2026-08-23)

**Status:** RESEARCH_INPUT only — not AUTHORITY. Does not change frozen laws or open gates without human dispatch.  
**Extends:** `DDR-CUE-SOA-00/NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md` (cs249r synthesis)  
**Program:** `NATIVE_V1_MINI_AI_BOARD_PASS` via Blueprint V2 Phases A–G (`17_`)

---

## Executive summary

Literature **confirms** the project’s memory-first bet. New sources add **actionable** detail in four bands:

1. **Transport (P0)** — AXI pipeline law from ZipCPU / bitwiz; AMD UG586 MIG reorder semantics  
2. **Graph IO (Phase B–C)** — GNN accelerator surveys + selective late materialization (SLM)  
3. **Memory hierarchy (Phase D–E)** — Chameleon dual replay; operation-partitioning (KARAT-style)  
4. **Learning (research lane)** — Continual replay + PA margin; not V1 critical path  

**Critical path unchanged:** close `ddr_cue_soa_00r_axi_liveness` (attempt 7: clone `ddr_wavefront_00` engine) → `ddr_cue_soa_bench_01` → then parallel WM trace / late materialize.

---

## A. Transport & MIG (Phase A — attempt 7+)

### A1. ZipCPU / bitwiz — AXI skid & ready law

| Source | Lesson for Native AI |
|--------|---------------------|
| [ZipCPU skid buffer](http://zipcpu.com/blog/2019/05/22/skidbuffer.html) | High-throughput AXI **requires** registered stall + 1-beat capture; combinatorial `r_ready` from FSM is fragile |
| [bitwiz — pipelining protocols](https://bitwiz.io/articles/pipelining-without-breaking-your-protocol/) | **Never** combinatorial `ready` loops across blocks; use 2-entry FIFO when bypass skid hurts timing |
| [Chipmunk Logic skid](https://chipmunklogic.com/digital-logic-design/designing-skid-buffers-for-pipelines/) | Pipeline skid = full decoupling (both ready and data registered) — 1 cycle latency, better Fmax |

**Project mapping (attempt 6 lesson):** cs249r plane-stationary **schedule** on wavefront did not fix MIG because **transport engine** is still layered. Attempt 7 should **instantiate proven `a7ng_cue_wavefront` read path** and attach SOA plane descriptors — not more orchestrator patches.

**Gate law:** `m_axi_rready` registered from FIFO capacity only (already in `DDR_CUE_SOA_00R_AXI_LIVENESS.md` §6).

### A2. AMD UG586 — MIG reorder vs AXI observation

| Source | Lesson |
|--------|--------|
| [UG586 Reordering](https://docs.amd.com/r/en-US/ug586_7Series_MIS/Reordering) | MIG may reorder DRAM commands (NORM/RELAXED); **AXI UI layer** returns R in request order via `ui_rd_data` |
| [Xilinx AR 34392](https://adaptivesupport.amd.com/s/article/34392) | Duplicate DDR physical reads after R stall ≠ necessarily duplicate DUT AR — classify at **AXI `ar_fire`/`r_fire`**, not `ddr3_model` col logs alone |

**Project mapping:** `FAILURE_CLASSIFICATION.md` already ruled `A_DUPLICATE_AR_ACCEPT`. Attempt 7 must add **TB monitor on `m_axi_araddr` first 4 ARs** before trusting DDR model ordering.

### A3. Recommended attempt 7 architecture (research-backed)

```text
SOA descriptor table (frozen 104b)
        ↓
a7ng_cue_wavefront-class burst engine   ← ddr_wavefront_00 PASS (clone)
        ↓
ZipCPU-style R register slice / 2-entry FIFO
        ↓
SOA unpack → ping/pong BRAM wave
```

**ONE UNKNOWN unchanged:** 832 B / 64 candidates lawful delivery.

---

## B. Graph retrieval IO (Phase B–C)

### B1. FPGA GNN surveys — hybrid memory/compute split

| Source | Relevant idea | Native AI adaptation |
|--------|---------------|---------------------|
| [Journal of Big Data 2024 GCN-FPGA survey](https://link.springer.com/article/10.1186/s40537-024-01022-4) | Aggregation = memory-intensive; combination = compute-intensive | **GRAPH phase** = DDR stream + BRAM wave; **LM phase** = compute-bound — reinforces phase ownership FSM |
| [FCS 2023 GNN accelerator survey](https://academic.hep.com.cn/fcs/CN/10.1007/s11704-023-3307-2) | Irregular memory + regular compute in same workload | Our graph scorer is regular; **DDR feed** is irregular — optimize bytes first |
| [arXiv 2412.15666 FPGA ML survey](https://arxiv.org/html/2412.15666v1) | Vertex clustering / data layout regularization | **Descriptor SOA** is our layout optimization — not full graph repartition |

**Do NOT port:** GCN layers, HBM, multi-SLR Alveo designs. **Do adopt:** explicit **phase labeling** in bench metrics (`memory_wait` vs `compute_wait`).

### B2. Selective late materialization (SLM)

| Source | Idea | Gate |
|--------|------|------|
| [SLM — VLDB 2025](http://people.iiis.tsinghua.edu.cn/~huanchen/publications/slm-vldb25.pdf) | Per-attribute **materialization point** minimizes fetch + copy cost | `graph_late_materialize_00` — fetch `node_cue` / episode payload only after Top-K |
| [GPUSparse arXiv 2606.26441](https://arxiv.org/abs/2606.26441) | Fused scatter-add scoring without full document materialization | Aligns with **score cheap early** — 104b descriptor stream before expensive fields |

**Iron-law:** Phase C must log which term improves: `B_query`, `BW_eff`, or `L_control`.

### B3. Operation partitioning (KARAT metaphor)

| Source | Idea | Native AI mapping |
|--------|------|-------------------|
| [KARAT — retrieval near memory](https://arxiv.org/html/2608.03555) | KV / index in memory-centric node; projections on compute node | **DDR** = persistent graph + LM weights; **BRAM** = hot wave + Top-K; **LM-06** = composer not store |

Not a hardware proposal — a **scheduling doctrine** for `bram_owner_00`.

---

## C. Memory hierarchy & continual learning (Phase D–E + research)

### C1. Chameleon — dual replay buffers

| Source | Idea | Project fit |
|--------|------|-------------|
| [Chameleon — TCAD 2023](https://doi.org/10.1109/tcad.2023.3347640) | Short-term replay in on-chip; long-term in off-chip | **02M episodes:** hot replay ring in BRAM, bulk in DDR — matches `AUTHORITY_MEMORY_DOCTRINE.md` |
| [CLFD — NeurIPS 2024](https://proceedings.neurips.cc/paper_files/paper/2024/file/9b224ace8963c9385ad5e2b5c9039b97-Paper-Conference.pdf) | Replay **features** not raw images — smaller footprint | Research for encoder lane only; not graph V1 |

**Gate:** `lm06_wm_trace_00` + episode store sizing — measure `M_peak` before BRAM cuts.

### C2. TinyEngine / MCUNet (already in cs249r doc)

Whole-network **lifetime scheduling** — required for `bram_owner_00` ship report (SPEC §28).

---

## D. Learning lane (post-V1 / research only)

| Source | Idea | Gate |
|--------|------|------|
| Crammer et al. — PA algorithms (already cited) | Online margin updates | `npu_v1_law_00` — pairwise φ scope |
| LoRA / AWQ (already cited) | Frozen backbone + bounded delta | After Native V1 freeze |
| Rolnick — experience replay (already cited) | Bounded episodic memory | 02M contract |

**Forbidden:** host-side gradient/winner; teacher hints in blind exam.

---

## E. What literature says NOT to do

| Temptation | Why reject for Arty A7 Native V1 |
|------------|----------------------------------|
| More PEs / wider SIMD | Roofline + `ddr_wavefront_00`: memory-bound |
| Port full GNN accelerator | Different workload; 8-class retrieval ≠ GCN training |
| HBM / multi-die | xc7a100t DDR3 only |
| Claim SOA ⇒ DDR solved | Ceiling ~1.23× if bandwidth-bound |
| Board before MIG XSim PASS | `00R` gate §14 |
| Layered FSM patches without proven engine | Attempts 1–6 evidence |

---

## F. Proposed gate / research extensions

| ID | Phase | ONE UNKNOWN | Source band | Priority |
|----|-------|-------------|-------------|----------|
| `ddr_cue_soa_00r_axi_liveness` attempt 7 | A | 832 B delivery | A1 + A3 | **P0** |
| `ddr_cue_soa_bench_01` | B | SOA vs AOS measured roofline | cs249r + B1 | P1 after A |
| `graph_late_materialize_00` | C | Expensive fetch after Top-K | B2 SLM | P2 |
| `lm06_wm_trace_00` | D | `u_a` M_peak lifetime | TinyTL + C2 | parallel |
| `episode_dual_replay_00` | research | BRAM ring + DDR bulk replay law | C1 Chameleon | post-V1 |
| `retrieval_fused_score_00` | research | Fused score without full materialize | B2 GPUSparse | post Phase C |

No new gate OPEN without `LOOP_STATE` + human dispatch.

---

## G. Recommended reading order (for implementers)

1. `ATTEMPT6_CS249R_DATAFLOW_PLAN.md` + `FAILURE_CLASSIFICATION.md`  
2. ZipCPU skid buffer + bitwiz ready/valid article (A1)  
3. UG586 Reordering § (A2) — AXI vs DDR physical logs  
4. `a7ng_cue_wavefront.sv` closeout (`ddr_wavefront_00`)  
5. SLM paper §1–3 for Phase C planning only  

---

## H. Authority statement

This document is **RESEARCH_INPUT**. Execution authority remains:

```text
evidence > LOOP_STATE > 17_ > this file
```

Human declares `NATIVE_V1_MINI_AI_BOARD_PASS`.
