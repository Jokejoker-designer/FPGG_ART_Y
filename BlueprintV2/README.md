# Native AI on Arty A7-100T — Complete Engineering Blueprint

## CURRENT AUTHORITY — read this first

| Layer | Authority |
|-------|-----------|
| **Architecture** | this package, `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` |
| **Live project state / current gate** | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` |
| **Current evidence** | latest audited gate closeouts under `results/A7-NATIVE-GRAPH/**` |
| **Evidence delta vs this package** | **[`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md)** — Masterplan V2 revision |
| **feedback + SPEC compliance** | [`STATUS/COMPLIANCE_INDEX.md`](../results/A7-NATIVE-GRAPH/STATUS/COMPLIANCE_INDEX.md) |

```text
Masterplan defines architecture.
LOOP_STATE defines current live execution.
Evidence defines truth.
```

**CHAT MEMORY IS NOT PROJECT AUTHORITY.**
**HISTORICAL NEXT INSTRUCTIONS ARE NON-AUTHORITATIVE.** Historical roadmap text in this package —
including stage ordering in `02_IMPLEMENTATION_ROADMAP.md` and any "start now with …" instruction —
must not override `LOOP_STATE.json`.

Read `00_CURRENT_AUTHORITY.md` before acting on any execution-state statement below.

---

This package is an implementation blueprint for a **Native FPGA AI V1** that learns post-bitstream, stores knowledge in FPGA-owned state, uses many physically parallel search/scoring lanes, stores large knowledge structures in DDR, keeps only the hot working set in BRAM, and uses LM-06 as a language composer rather than as the sole knowledge store.

## Target final claim

> An FPGA-native online-learning, memory-augmented small AI system on the Arty A7-100T, with a learned query/representation path, FPGA-owned episodic/relational knowledge memory, parallel graph search, an 802,816-parameter Transformer backbone, post-bitstream learning, teacher-off held-out retrieval, and FPGA-generated responses.

This package deliberately does **not** claim open-domain LLM behavior, human-level understanding, or thousands of physically independent AI cores.

## Current project evidence carried into this blueprint

All rows below are `POST_ROUTE` for separate bitstreams unless noted.

- A0.3 encoder: routed board bit uses 8,107 LUT, 7,154 FF, 3 BRAM, 0 DSP at 100 MHz scope.
- A0.3 twin ↔ board: 5,000/5,000 learning transactions exact for `d1` and `dH` after the required `e_ra` alignment prime.
- 01R routed: 1,252 LUT, 1,322 FF, 56 BRAM, 0 DSP.
- 02M routed: 1,704 LUT, 2,332 FF, 52 BRAM, 0 DSP.
- LM-06 routed: 37,555 LUT, 35,864 FF, 132 BRAM, 154 DSP. Those 132 tiles are LM-06 **working machinery** (`u_a` 66 activation, `u_w` 64 weight staging, `u_snap` 2), not a persistent weight store — LM-06 persistent weights are already DDR-resident. See `00_CURRENT_AUTHORITY.md` §3.
- Naive sum of four separate bitstreams: 48,618 LUT, 46,672 FF, 243 BRAM, 154 DSP. BRAM = 180% of the xc7a100t device. Naive stacking is **FALSIFIED**, not an open estimate; later SoC measurements record 260/135 and 264/135 for other naive compositions (`00_CURRENT_AUTHORITY.md` §4).
- Encoder lane status: **OPEN / PARKED**. Its next step is defined by encoder authority (`MUST_READ_UNBLOCK_H5.md`), not by this package. The graph architecture is a **new branch**, not permission to rewrite or erase the existing 03E evidence lineage, and not permission to glue a partial encoder into a graph PASS.

Execution state for every subsystem — including which gates are OPEN, BLOCKED or NOT_EVIDENCED — is in `00_CURRENT_AUTHORITY.md` §20, not in this list.

## Package map

0. `00_CURRENT_AUTHORITY.md` — **Masterplan V2 evidence delta**: corrections, current status table, planned memory research, authority order.
1. `01_SYSTEM_BLUEPRINT.md` — complete system architecture.
2. `02_IMPLEMENTATION_ROADMAP.md` — staged execution plan with GO/NO-GO gates.
3. `03_MINESWEEPER_TRAINING_GAME.md` — detailed teacher/student game mechanics.
4. `04_HARDSTOPS.md` — scientific, hardware, teacher-boundary and claim hard stops.
5. `05_PARALLEL_AGENT_ENGINE.md` — FPGA PE swarm, top-K and frontier architecture.
6. `06_KNOWLEDGE_GRAPH_AND_ATTENTION.md` — graph schema, query attention and scoring.
7. `07_TEACHER_AUDITOR_PROTOCOL.md` — PC teacher/auditor protocol without host-side learning.
8. `08_MEMORY_ARCHITECTURE.md` — DDR/BRAM architecture and 800k scale path.
9. `09_LM06_LOWBIT_OPTIMIZATION.md` — W4/W2 mixed-precision optimization lane.
10. `10_VALIDATION_AND_EVIDENCE.md` — training, blind exam, board and provenance gates.
11. `11_RESOURCE_CAPACITY_THROUGHPUT.md` — physical/logical agent capacity and theoretical throughput.
12. `12_FAILURE_DECISION_TREE.md` — disciplined failure branches.
13. `13_CURSOR_MASTER_PROMPT.md` — paste-ready implementation orchestrator prompt.
14. `14_FINAL_ACCEPTANCE_CHECKLIST.md` — final Native V1 closure checklist.
15. `15_CURSOR_BLUEPRINT_LOOP.md` — re-read pack; **session STOP after CLOSEOUT** while `LOOP_STATE.session_override.forbid_queue_self_chaining` is true.
16. `contracts/` — machine-readable interface examples.
17. `templates/` — experiment closeout template.
18. `tools/capacity_estimator.py` — editable resource/throughput estimator.

## Core doctrine

```text
FITS != RUNS != TRAINS != CONVERGES != USEFUL
SIMULATION != BOARD
XSIM != BOARD
MIG_XSIM != BOARD_MIG
POST_ROUTE != FUNCTIONAL_INTEGRATION
LOGICAL AGENTS != PHYSICAL PARALLEL LANES
TEACHER SUPERVISION != HOST OPTIMIZATION
MEMORY CAPACITY != PARAMETER COUNT
```
