# 02 — Implementation Roadmap

> **Masterplan V2 note.** This file is split into three parts:
>
> - **A. ORIGINAL ARCHITECTURAL MILESTONES** — preserved verbatim below. Historical structure; do not
>   delete, do not re-execute from the top.
> - **B. CURRENT COMPLETION / SUPERSESSION MAP** — what each milestone actually produced, with the
>   exact evidence class and artifact.
> - **C. CURRENT REMAINING DEPENDENCY ROADMAP** — what is genuinely still ahead.
>
> **Part A is not a live queue.** The live queue is
> `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json`. Read
> [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md) before treating anything in Part A as a
> current instruction.

---

# A. ORIGINAL ARCHITECTURAL MILESTONES (historical structure — preserved)

## Stage 0 — Freeze authority

Before new code:

- preserve all frozen bitstreams and SHA values;
- preserve current 03E negative/partial results;
- preserve 5,000/5,000 A0.3 board/twin trace evidence;
- preserve routed utilization reports;
- create a new branch/milestone namespace: `A7-NATIVE-GRAPH-*`.

Do not overwrite 01R, 02M, LM-06 or A0.3.

---

## NG-00 — Contract and teacher boundary

Deliver:

- lesson packet schema;
- telemetry schema;
- teacher/auditor separation;
- train/eval state machine;
- anti-leak tests.

PASS:

```text
No host gradient
No host ΔW
No host cue/hash
No host winner/address
No host next token
No teacher attention hint in final exam
```

---

## NG-01 — 16-lane scorer microarchitecture

Build only a scoring kernel.

Inputs per lane:

```text
candidate feature record
query feature record
path state
```

Output:

```text
signed score
candidate ID
flags
```

Target:

```text
Fmax >= 100 MHz
II = 1 candidate/lane/cycle after pipeline fill
16 physical lanes minimum target
```

Do not add DDR graph traversal yet.

PASS requires XSim exactness and routed timing.

---

## NG-02 — Parallel Top-K and bucket frontier

Avoid a CPU-style heap. Use FPGA-friendly score buckets or comparator trees.

Recommended:

```text
16 scorer outputs
    ↓
Top-K reduction tree (K=4 or 8)
    ↓
priority bucket FIFO
```

PASS:

- deterministic ranking;
- stable tie rule;
- no dropped candidate;
- bounded queue overflow behavior.

---

## NG-03 — DDR shard + BRAM hotset

Implement:

```text
DDR topic shard
→ burst DMA
→ BRAM hotset
→ PE swarm
```

Cold nodes must be scored cheaply before expensive adjacency fetch where possible.

PASS:

- no full graph scan;
- measured DDR bytes/query;
- measured cache hit ratio;
- measured candidate count/query.

---

## NG-04 — Minesweeper contextual pruning

Implement safe/relevant, weak, and bomb/irrelevant outcomes without deleting knowledge.

PASS:

- bomb prunes only current path;
- another query can later make the same node relevant;
- no permanent node blacklist from one query.

---

## NG-05 — Local edge/node learning

Start with small signed local weights and reward buckets.

Example reward values:

```text
+3 strong relevant
+1 weak relevant
 0 neutral
-1 irrelevant
-3 contradiction / hard bomb
```

FPGA computes update internally.

PASS:

- teacher-off state persists;
- reset removes learned behavior;
- retrain creates different behavior;
- host cannot inject updated edge weights.

---

## NG-06 — Multi-agent shared frontier

Target first:

```text
16 physical lanes
256 logical agent contexts
```

Then scale logical contexts independently from PE count.

PASS:

- agents share learned memory;
- one failed path does not reset another;
- deterministic arbitration/reduction;
- no starvation.

---

## NG-07 — Native query anchors

Teach the FPGA to derive at least:

```text
ENTITY
INTENT
CONTEXT
```

Teacher may supervise during TRAIN but cannot send these fields during blind EVAL.

PASS examples:

```text
"What is FPGA?"        → FPGA + DEFINE
"How does FPGA work?"  → FPGA + MECHANISM
"FPGA vs CPU?"         → FPGA/CPU + COMPARE
```

with held-out wording.

---

## NG-08 — Kidi-20 Minesweeper curriculum

Use 20 facts from one or two bounded topics.

TRAIN:

- teacher reads Markdown;
- teacher creates questions and relevance rankings;
- native agents explore and update graph.

BLIND EXAM:

- teacher off;
- held-out wording;
- unrelated distractors;
- contradiction probes.

PASS must be preregistered.

---

## NG-09 — Kidi-40 multi-intent exam

Expand to:

```text
DEFINE
MECHANISM
COMPARE
CAUSE
PART_OF
```

PASS requires correct attention shift for the same entity under different intent.

---

## MEM-00 — BRAM ownership audit

This runs as a parallel architecture lane, but integration waits for graph gates.

Reason: naive four-block BRAM sum is 243/135 = 180%.

Audit all 132 LM-06 BRAM tiles by hierarchy and lifetime.

Classify each tile:

```text
persistent
transient
shareable-by-phase
DDR-backable
quantization-sensitive
```

---

## MEM-01 — DDR-backed episodic/fact store

Move persistent episode/fact data out of 02M-private BRAM.

PASS:

- FPGA generates addresses;
- flush/reload persistence;
- teacher-off exact retrieval;
- no host winner/address.

---

## MEM-02 — DDR-backed router/index

Move bulk index from 01R-private BRAM while preserving final full-cue authority.

PASS:

- no hidden linear scan;
- bounded candidates/query;
- unchanged final matching law.

---

## LM-Q0 — LM-06 BRAM ownership audit

Do this before quantization RTL.

Quantization is useful only if it actually releases the scarce resource.

---

## LM-Q1 — W4A8 reference model

Keep LM-06 frozen baseline intact. Build an alternate Q4 candidate.

PASS:

- quality regression within preregistered bound;
- lower weight bandwidth/storage;
- no new timing failure.

---

## LM-Q2 — FPGA-native W2A8 / ternary candidate

Learn from BitNet principles, not by copying CPU/GPU kernels.

Recommended initial representation:

```text
weight code ∈ {-1,0,+1}
8-bit activation
wide accumulator
block scale
```

Prefer FPGA-friendly power-of-two scales when quality permits.

Do not make native W2 LM training part of V1 unless separately proven. V1 may use a frozen low-bit LM backbone while encoder/graph memory learns online.

---

## INT-00 — Shared memory map and MIG arbitration

Define fixed DDR regions for:

```text
LM weights
knowledge nodes
edge lists
episodes
router/index
telemetry/replay
```

PASS:

- no address overlap;
- no starvation;
- measured arbitration bandwidth;
- integrity under concurrent traffic.

---

## INT-01 — Graph + 01R/02M semantics

Integrate only after graph and memory gates pass.

Do not retune frozen router thresholds to hide a weak graph encoder.

---

## INT-02 — LM-06 composer

Feed only structured Native evidence to LM-06.

Host cannot select or write the final answer.

---

## SCALE ladder

```text
20
40
256
4,096
16,384
65,536
262,144
800,000 episodes
```

At every rung measure:

```text
candidate/query
DDR reads/query
DDR writes/train
cache hit
latency
false hit
miss
queue overflow
index bytes
episode bytes
```

---

## FINAL — Native AI V1 board closeout

Required sequence:

```text
fixed bitstream
→ novel post-bitstream training
→ teacher OFF
→ held-out query
→ native query attention
→ parallel graph retrieval
→ structured evidence
→ LM-06 FPGA generation
→ final response
→ reset/forget
→ retrain different mapping
→ new behavior
```

---

# B. CURRENT COMPLETION / SUPERSESSION MAP

Status vocabulary: `PASS | PASS_NARROW | DONE_ENG | LIMIT | OPEN | BLOCKED | NOT_EVIDENCED`.
No status is inferred from an adjacent milestone. For a completed or superseded milestone, go to the
evidence — **do not reimplement it**.

| Milestone | Status | Evidence class | Canonical artifact | Supersession / note |
|-----------|--------|----------------|--------------------|---------------------|
| Stage 0 freeze authority | DONE_ENG | POST_ROUTE (frozen SHA MATCH) | `results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET_SOC.json` | frozen LM-06 / 01R / 02M / A0.3 SHAs re-verified each gate |
| NG-00 contract + teacher boundary | DONE_ENG | HARNESS | `tests/native_graph/test_ng00_anti_leak.py` | anti-leak pytest only; not a silicon boundary proof |
| NG-01 16-lane scorer | DONE_ENG | XSIM + POST_ROUTE | `results/A7-NATIVE-GRAPH/NG-01/closeout.md` | 16 lanes, WNS +2.400, TNS 0, LUT 618, BRAM 0, DSP 0 |
| NG-02 Top-K + frontier | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-TOPK/closeout.md` | **superseded** by NG-02R-TOPK: original pair-winner Top-K was a SEV-0 correctness defect; bitonic global Top-8 replaces it |
| — lossless flow repair | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-FLOW/closeout.md` | added after NG-02; no candidate loss under randomized backpressure |
| NG-03 DDR shard + BRAM hotset | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-03/` | **superseded for DDR measurement** by DDR-FEED → MIG-RIVAL → MIG-METRIC-00 |
| NG-04 contextual pruning | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-04/closeout.md` | stale-event handling folded into NG-06R-EPOCH |
| NG-05 local edge/node learning | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-05/closeout.md` | persist gate archived at `NG-05/GATE_ng05_persist.md` |
| NG-06 multi-agent shared frontier | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-06/GATE_ng06.md` | utilisation and death claims **superseded** by NG-06R-WIDE + NG-06R-EPOCH |
| — wide dispatch | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-WIDE/AUDIT_ng06_wide_sci_r3.md` | utilisation under varied ready patterns still open |
| — query/path epochs | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-EPOCH/AUDIT_ng06_epoch.md` | `DROP_STALE`; alive = 256 |
| NG-07 native query anchors | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-07/GATE_ng07.md` | not a blind silicon exam |
| NG-08 Kidi-20 curriculum | DONE_ENG | XSIM + HARNESS | `results/A7-NATIVE-GRAPH/NG-08/GATE_ng08.md` | harness ≠ HS-02 |
| NG-09 Kidi-40 multi-intent | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-09/GATE_ng09.md` | same limit |
| — TermGen (added after NG-09) | DONE_ENG | XSIM + OOC | `results/A7-NATIVE-GRAPH/TERMGEN/AUDIT_termgen.md` | 4 families exact at n=32, DSP 0; required before any complete-candidate throughput claim |
| — PERFMON (added) | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/PERFMON/AUDIT_perfmon.md` | per-lane counters absent on the MIG feed path |
| — frontier shootout (added) | DONE_ENG | XSIM + OOC | `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/AUDIT_frontier_shootout.md` | winner `B_systolic` |
| MEM-00 BRAM ownership audit | DONE_ENG | POST_ROUTE | `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` | result: `u_a` 66 / `u_w` 64 / `u_snap` 2 — working machinery, not weight store |
| MEM-01 / MEM-02 DDR-backed stores | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/MEM-01_02/GATE_mem01_mem02.md` | board persistence still open |
| — memory record schema freeze | DONE_ENG | XSIM + pytest | `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/AUDIT_mem_schema_v1.md` | Node16 / Edge32 / Episode32; repo-wide stride freeze still QUEUED |
| — BRAM working memory WM-00 | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/BRAM-WM-00/AUDIT_bram_wm_00.md` | §45 `BRAM_WORKING_MEMORY_ARCH_PASS` **not** declared |
| — WM-00 OOC timing | PASS_NARROW | OOC_POST_ROUTE | `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/AUDIT_wm00_timing.md` | WNS +0.069 / TNS 0; CONTROL −290.499 archived |
| LM-Q0 LM-06 BRAM ownership audit | DONE_ENG | POST_ROUTE | `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` | same audit as MEM-00 |
| LM-Q1 W4A8 / LM-Q2 W2A8 | OPEN | — | — | not started; MEM-00 shows weight precision is **not** the load-bearing BRAM lever |
| INT-00 shared memory map + MIG arbitration | PASS_NARROW | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/INTEGRATE/AUDIT_integrate_fit_soc.md` | PE 16 fabric, WNS +0.952; LM-06 weights ABSENT on that bit |
| — DDR feeder measurement integrity | PASS | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` | per-run deltas; full grid on silicon in mig_board_r2 |
| — MIG silicon grid (mig_board_r2) | DONE_ENG | BOARD_MIG | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_mig_board_r2.md` | 16/16 burst×outstanding; quarantine superseded |
| — MIG silicon row (mig_board legacy) | PASS_NARROW | BOARD_MIG | `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md` | pre-metric rows **quarantined** only |
| — DDR wavefront characterization | DONE_ENG PASS_NARROW | MIG_XSIM_WAVEFRONT | `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/` | throughput not improved vs control |
| — LM-06 WM bit-exact (lm06_wm_00) | DONE_ENG PASS_NARROW | LM06_WM_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_lm06_wm_00.md` | ladder BLOCKED until human re-open |
| INT-01 graph + 01R/02M semantics | OPEN | — | — | migration and law retuning must stay separate experiments |
| INT-02 LM-06 composer | LIMIT | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` | evidence compose exists (`LM_COMPOSE/GATE_lm_compose.md`); answer path absent — HS-22 OPEN |
| SCALE ladder | NOT_EVIDENCED | ABSENT | `results/A7-NATIVE-GRAPH/STATUS/AUDIT_section14.md` | no 800k archive; bytes/query and candidates/query unmeasured |
| FINAL Native AI V1 board closeout | NOT_EVIDENCED | CHECKLIST_MAP | `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md` | GOAL not met; human declares |

---

# C. CURRENT REMAINING DEPENDENCY ROADMAP

This is **architecture guidance**, not the live queue. The live queue is
`results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` — always re-read it, because it moves. The status
words below are the dependency shape, not a live snapshot; see
[`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md) §10.2.

## C.1 Memory dependency chain

```text
MIG measurement integrity            CLOSED   (mig_metric_00 MIG_XSIM PASS)
        ↓
MIG silicon full grid                CLOSED   (mig_board_r2 BOARD_MIG 16/16)
        ↓
DDR / wavefront characterization     CLOSED   (ddr_wavefront_00 PASS_NARROW XSim)
        ↓
LM-06 working-set equivalence        CLOSED   (lm06_wm_00 PASS_NARROW XSim — bit-exact CONTROL)
        ↓
LM-06 BRAM working-set ladder        BLOCKED  (human re-open; Pareto 96/64/48/32 — 32 not mandatory)
        ↓
BRAM owner / phase-share             BLOCKED  (bram_owner_00)
        ↓
integrated Native memory map         BLOCKED  (full_integration)
```

Live orchestrator stop: `LOOP_STATE.next = STOP` until human re-opens ladder.

Cutting LM-06's 132 tiles before DDR delivery buffering is measured would choose the ladder targets
blind. Definitions for each of these gates are in
[`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md) §11–§12.

## C.2 Semantic / claim chain

```text
teacher-off framing (UART)           PASS_NARROW
        ↓
teacher-off SEMANTIC retrieval       OPEN     (held-out wording on silicon)
        ↓
LM-06 active answer path (HS-22)     LIMIT    (TinyGPT/DSP core absent; additive BRAM 264 > 135)
        ↓
scale ladder 20 → 40 → … → 800k      NOT_EVIDENCED
        ↓
§14 acceptance → human BOARD_PASS    NOT_EVIDENCED
```

## C.3 Queued but not dispatchable

Recorded in `LOOP_STATE.json` with `status = QUEUED`; the dispatcher ignores them. Listed here so
they are not forgotten, **not** so they are started:

- ~~`mig_sweep_full`~~ — **MERGED/DONE** as `mig_board_r2` (16/16 silicon).
- `bram_ownership_report` — SPEC §28 ownership report at **Native V1 ship** scope (extend `INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md`).
- `record_schema_freeze` — one authoritative Node/Edge/Episode record across RTL, Python, TB, loader.
- `mig_pe_wide` — multi-lane service; **fold into `ddr_wavefront_00`**, do not run both.

## C.4 Research-only, not roadmap

- **HNSW** — `RESEARCH_ALLOWED, DATAPATH_NOT_APPROVED`. May open only after 01R-only scaling shows a
  measured candidates/query, bytes/query or latency problem. `M = 16` matching 16 PEs is a
  coincidence, not evidence.
- **Encoder / A0.3 lane** — OPEN / PARKED under its own authority (`MUST_READ_UNBLOCK_H5.md`). Not a
  graph-lane dependency and never glued into a graph PASS.
- **803k → 1.5M parameters** — a possible future scalability consequence, not a Native V1 gate.
