# 00 — CURRENT AUTHORITY (Masterplan V2 revision)

> **CURRENT (2026-09-03):** Gate14 epoch/P_BOOT silicon is `BOARD_CLOSED`
> on bit `1F0F2ABB…` commit `9656245`. Do **not** start from the August
> `LOOP_STATE.json` NEXT (`ddr_cue_soa_00r_axi_liveness`). Live pointer:
> `results/A7-NATIVE-GRAPH/GROK-ORCH-00/CURRENT_GATE14_STATUS.md`.
> This file below remains the **HISTORICAL** 2026-08-22 evidence delta.

**Revision:** Masterplan V2 · **Written:** 2026-08-22 · **Reconciled:** 2026-08-22 (wavefront closeout) · **Scope:** documentation reconciliation only.

This file is the **evidence delta** between the original blueprint (`01`–`15`, written before
A7-NATIVE-GRAPH executed) and what the repository can actually prove today. It does not replace the
architecture in `01`–`15`; it corrects execution state and adds current evidence.

```text
PRESERVE VALID ARCHITECTURE
PATCH STALE EXECUTION STATE
ADD CURRENT EVIDENCE DELTA
```

---

## 1. Authority order

A newer, higher-class artifact always wins. The Masterplan may **not** override newer evidence.

```text
1. BOARD / POST_ROUTE / XSIM raw evidence
2. current contracts (docs/contracts/**, docs/native_graph/CONTRACT_FREEZE.md)
3. results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json      <- live execution authority
4. audited closeouts (results/A7-NATIVE-GRAPH/**/AUDIT_*.md, GATE_*.md, CLOSEOUT.md)
5. this Masterplan package (docs/NATIVE_AI_ARTY_A7_BLUEPRINT/**)
6. historical notes and planning estimates
```

```text
Masterplan defines architecture.
LOOP_STATE defines current live execution.
Evidence defines truth.
```

**CHAT MEMORY IS NOT PROJECT AUTHORITY.**
**HISTORICAL NEXT INSTRUCTIONS ARE NON-AUTHORITATIVE** — including any "START NOW WITH NG-00" text,
any roadmap ordering in `02_IMPLEMENTATION_ROADMAP.md`, and any remembered summary of this package.

Locked memory doctrine input: `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`.

---

## 2. REQUIRED CORRECTION BOX

| # | Correction | Source |
|---|------------|--------|
| **1** | **LM-06 persistent weights were already DDR-resident.** The 132 BRAM tiles are LM-06 *working machinery* (weight staging `u_w` 64, activation scratch `u_a` 66, snapshot `u_snap` 2), **not** a persistent 784 KiB model store. Phrasing such as "move 802,816 weights from BRAM to DDR" is **forbidden**. | `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` |
| **2** | **Naive BRAM stacking is FALSIFIED, not an open estimate.** Measured naive compositions: 243/135 (four frozen blocks), 260/135 (UA SoC 128 + frozen LM-06 132), 264/135 (consol 132 + TinyGPT-class LM-06 132). All exceed the 135-tile device. | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md`; `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |
| **3** | **MIG `2048 bytes / 80 bursts` was a CUMULATIVE CONTROL reading, not a per-run metric.** The per-run interpretation of 2048/80 is **FALSIFIED**. `MIG-METRIC-00` produced the corrected per-run deltas. | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md` |
| **4** | **MIG-BOARD evidence belongs to its archived RTL/bit revision.** `MIG-METRIC-00` changed the DDR feeder RTL *after* that bitstream. The revised feeder does **not** inherit BOARD evidence. | `results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md` |
| **5** | **16 physical lanes do not imply DDR can feed 16 fresh records per cycle.** Lane count proves parallel scoring capability, not memory delivery. | `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §6 |
| **6** | **The Masterplan roadmap is architecture guidance; `LOOP_STATE.json` is live execution authority.** Where they disagree, LOOP_STATE decides what runs next. | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` |

---

## 3. LM-06 memory truth

LM-06 persistent INT8 weights are **already DDR-resident by contract**. The BRAM problem is the
LM-06 **working machinery**, not storage of the 802,816 persistent parameters.

Measured ownership of the 132 tiles in the frozen LM-06 post-route checkpoint:

| owner | tiles | role | evidence class |
|-------|------:|------|----------------|
| `u_a` | 66 | activation scratch | POST_ROUTE |
| `u_w` | 64 | weight staging / working tiles | POST_ROUTE |
| `u_snap` | 2 | snapshot machinery | POST_ROUTE |
| **total** | **132** | working set, not persistent store | POST_ROUTE |

Source: `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` (132 `BMEM` primitives
enumerated from `build/out/a7lm06_post_route.dcp`).

Arithmetic that settles the question: 64 tiles × 36 Kbit = 2.36 Mbit, while an 8-bit image of
`P_LM = 802,816` is 6.42 Mbit. `u_w` can hold at most ~37% of the model, so it **cannot** be the
weight store.

Open sub-question, still unresolved and **not** to be assumed: is `u_w` sized by logical tile shape
(low-bit weights would free tiles) or by available BRAM (low-bit weights would free nothing and show
up as DDR bandwidth instead)? Settle it by reading LM-06 buffer sizing, not by inference.

---

## 4. The actual BRAM integration problem

| composition | BRAM | device | verdict | evidence class | artifact |
|-------------|-----:|------:|---------|----------------|----------|
| LM-06 132 + 01R 56 + 02M 52 + A0.3 3 | **243** | 135 | naive stack **FALSIFIED** | POST_ROUTE (four separate bits) | `docs/native_graph/RESOURCE_BUDGET.md` |
| UA SoC 128 + frozen LM-06 132 | **260** | 135 | naive stack **FALSIFIED** | POST_ROUTE_FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md` |
| consol 132 + TinyGPT-class LM-06 132 | **264** | 135 | naive stack **FALSIFIED** | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |

**NAIVE STACKING = FALSIFIED.** This is a measured architectural FAIL (HS-11), not a warning and not
an open estimate.

`UA128 + full LM06` must **not** be presented as a final architecture. LM-06 already owns `u_w` and
`u_a`; that composition double-counts the same functional memory.

A measured capacity co-fit exists — shared pool = max(UA 128, LM-06 132) = 132 tiles, WNS +0.586,
TNS 0 — but its own audit records it as `POST_ROUTE_PROXY` with HS-22 **OPEN**, and the soft
objective ≤130 tiles **not met**.
Source: `results/A7-NATIVE-GRAPH/BRAM-CONSOL/METRICS.json`,
`results/A7-NATIVE-GRAPH/BRAM-CONSOL/AUDIT_bram_consolidate.md`.

---

## 5. Final memory hierarchy (authority)

```text
DDR
  persistent large state:
  LM persistent weights, graph nodes, edges, episodes,
  indices, learned persistent state, checkpoints

BRAM
  bounded ACTIVE WORKING SET only:
    LM phase    - weight tile, activation tile, scratch/KV, snapshot working data
    GRAPH phase - candidates, frontier, Top-K evidence,
                  agent/path context, pending learning updates

LUTRAM / FF
  ultra-hot state, queues, control

DSP / LUT arithmetic
  compute
```

Objective is a **bounded** BRAM working set — ideally independent of total parameter count where
practical. Not zero BRAM.

---

## 6. Phase sharing — correct definition

Naive simultaneous sharing ("GRAPH and LM both access `u_a` at once") is **unsuitable** and is listed
as forbidden in the locked doctrine.

Correct protocol:

```text
GRAPH
  -> BLOCK_NEW_WORK
  -> DRAIN_PE
  -> DRAIN_QUEUE
  -> DDR_COMMIT_IF_DIRTY
  -> VERIFY_QUIESCENT
  -> OWNER_SWITCH
  -> LM
  -> DRAIN
  -> OWNER_SWITCH
  -> GRAPH
```

Ownership state concepts: `owner`, `epoch`, `valid`, `dirty`, `generation` where applicable. Stale
entries die by those fields; payload scrubbing per switch is not required.

**Hard invariant:** one physical bank has at most one writer authority in one cycle.

**Status: FUTURE INDEPENDENT EXPERIMENT (`bram_owner_00`, BLOCKED).** The Masterplan may not claim it
implemented. Source: `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`.

---

## 7. Ping-pong / working-set doctrine

Preserved from the original design intent:

```text
DDR burst -> BRAM tile A / tile B -> compute
with ping-pong overlap where evidence later supports it
```

Rejected:

- `DDR -> one individual weight -> one MAC` (per-element DDR access)
- "zero-BRAM LM"

---

## 8. Current MIG evidence

### 8.1 MIG-BOARD — `mig_board = PASS_NARROW`, evidence class `BOARD_MIG`

| row | stall_frac |
|-----|-----------:|
| (burst 1, outstanding 1) | 0.923261 |
| (burst 4, outstanding 8) | 0.585366 |

Source: `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md`,
`results/A7-NATIVE-GRAPH/MIG-BOARD/BOARD_MIG_SWEEP_ROW.md`. WNS +1.068 ns.

**Never** convert these rows into a Native V1 BOARD_PASS. **Never** invent GB/s from them.

**Quarantine (carried):** these rows were captured with pre-metric **cumulative** counters, and the
old `DROP` counter was backpressure-derived. They are not citable as trusted per-run board traffic.
Source: `results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md`.

### 8.2 MIG-METRIC-00 — `mig_metric_00 = PASS`, evidence class `MIG_XSIM`

Marker `A7NG_MIG_METRIC_XSIM_PASS`. Authoritative **per-run** deltas at N = 64:

| burst | outstanding | axi_read_bytes | axi_read_bursts | axi_read_beats | data_mismatch | exp/rcv/cons |
|------:|------------:|---------------:|----------------:|---------------:|--------------:|-------------:|
| 1 | 1 | 1024 | 64 | 64 | 0 | 64/64/64 |
| 4 | 8 | 1024 | 16 | 64 | 0 | 64/64/64 |

Source: `results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md`,
`results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md`.

The older `2048 bytes / 80 bursts` reading is **CUMULATIVE CONTROL — NOT A PER-RUN METRIC**, and the
per-run 2048/80 interpretation is **FALSIFIED**.

`RVALID && !RREADY` must be called **R-channel backpressure**, never data drop, unless an actual
conservation failure exists. Conservation authority is record/data equality
(`expected = received = consumed`), not a backpressure counter.

### 8.3 CRITICAL evidence-lineage note

`MIG-METRIC-00` changed DDR feeder RTL **after** the earlier `mig_board` bitstream
(`EF94BA6B…08B2EF1`). Therefore:

- board evidence belongs to **its archived bit/RTL revision**;
- `MIG-METRIC-00` belongs to the **revised RTL** and is `MIG_XSIM` evidence;
- **board evidence is not automatically inherited by revised RTL.**

Never imply "new revised feeder = BOARD_PASS" without a new bitstream, a new SHA, and a new silicon
run. This scopes the old board evidence correctly; it does not weaken it — WNS +1.068 and the
Digilent AXI `mig.prj` SHA MATCH remain valid facts about that revision.

---

## 9. DDR bottleneck

DDR **capacity** is not the primary problem. DDR **delivery and locality** is.

Arty A7 raw link is ~16-bit @ 667 MT/s ≈ **1.33 GB/s theoretical raw**
(`ENGINEERING_ESTIMATE`, device-level arithmetic). Do not confuse theoretical link bandwidth with
measured graph throughput.

A 16-lane engine cannot sustainably receive 16 fresh 16-byte NodeRecords every cycle directly from
DDR. Sixteen 16-byte records per cycle at 100 MHz would be 25.6 GB/s — roughly 19× the theoretical
raw link.

**ENGINEERING DIRECTION / NEEDS EXPERIMENT** (not completed evidence):

```text
DDR burst
  -> compact candidate/cue working set
  -> ping-pong buffer
  -> parallel compute wavefront
  -> Top-K
  -> full metadata fetch only where justified
```

---

## 10. Next memory research order

Two different things, kept apart on purpose.

### 10.1 ARCHITECTURAL ROADMAP (dependency order — guidance)

```text
MIG measurement integrity        CLOSED (mig_metric_00 PASS, MIG_XSIM)
        ↓
DDR / wavefront characterization
        ↓
LM-06 working-set equivalence
        ↓
LM-06 BRAM working-set ladder
        ↓
BRAM owner / phase-share
        ↓
integrated Native memory map
```

Rationale: cutting LM-06's 132 tiles before DDR delivery buffering is measured would choose
96/64/48/32 targets blind.

### 10.2 LIVE LOOP AUTHORITY

`results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` is the **sole** live NEXT authority. This package
does not edit it and is not a substitute for reading it.

**Live snapshot (read LOOP_STATE first; this table is a copy, not a substitute):**

| field | value | class |
|---|---|---|
| `LOOP_STATE.next` | `STOP` | live execution |
| `LOOP_STATE.updated` | `2026-08-22T08:00:00+00:00` | live |
| `mig_board_r2` | DONE_ENG **PASS** | `BOARD_MIG` 16/16 silicon |
| `ddr_wavefront_00` | DONE_ENG **PASS_NARROW** | `MIG_XSIM_WAVEFRONT` |
| `lm06_wm_00` | DONE_ENG **PASS_NARROW** | `LM06_WM_XSIM` bit-exact CONTROL |
| `lm06_wm_ladder` | **BLOCKED** | human re-open only |
| Native V1 BOARD_PASS | NOT_EVIDENCED | — |

Wavefront closeout: `CLOSEOUT_ddr_wavefront_00.md`. LM06-WM closeout: `CLOSEOUT_lm06_wm_00.md`. MIG board: `CLOSEOUT_mig_board_r2.md`.

| | value |
|---|---|
| recommended architectural next | **HUMAN** re-open `lm06_wm_ladder` (Pareto BRAM ladder) **or** queued doc gates (`bram_ownership_report`, `record_schema_freeze`) — **separate sessions** |
| live authority | `LOOP_STATE.json` → `STOP` until human reopen |

If they ever disagree, record both separately and follow LOOP_STATE for execution.

### 10.3 Session chaining — one recorded supersession

`15_CURSOR_BLUEPRINT_LOOP.md` §2 step 5 says "PASS → start NEXT queue item in the SAME session".
That instruction is **superseded by live execution authority** while `LOOP_STATE.json` carries:

```text
session_override.forbid_queue_self_chaining = true
session_override.one_unknown_per_session    = true
session_override.stop_after                 = "mig_board_r2"
```

The working flow is `IMPLEMENT -> VERIFY -> AUDIT -> CLOSEOUT -> STOP`. Cursor must not chain
hardware-law changes automatically. When the override is lifted in LOOP_STATE, §2 step 5 applies
again. This is a recorded supersession, not a rewrite of `15_`.

---

## 11. DDR-WAVEFRONT-00 — contract + current class

**Status (live):** DONE_ENG **PASS_NARROW**, `Evidence_class=MIG_XSIM_WAVEFRONT`.  
**Not:** BOARD, Native V1, 16-PE DDR feed BOARD_PASS, throughput win.

Canonical: `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_ddr_wavefront_00.md`  
Marker: `A7NG_DDR_WAVEFRONT_XSIM_PASS`.

The original Masterplan-V2 draft labelled this gate PLANNED because it was authored while OPEN.
**Evidence outranks that draft.** Numbers live in the closeout, not as a second copy here.

**Scope of this package's endorsement: none.** The Masterplan V2 revision is a documentation task. It
performed no independent verification of the closing evidence, re-derived none of its numbers, and
therefore **endorses no result** of this gate. It records the class that `LOOP_STATE.json` carries so
that this file does not contradict live authority — that is a pointer, not a corroboration. Anyone
relying on the outcome must read the closeout and its auditor line, which record the gate's own
limits: a self-downgrade to PASS_NARROW on no throughput win, a duplicate-implementer dispatch
process finding, and an uncited concurrent artifact set
(`results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`).

Downstream gates were not unblocked: `lm06_wm_00`, `lm06_wm_ladder` and `bram_owner_00` remain
**BLOCKED** in LOOP_STATE.

**Contract (unchanged by the outcome):**

**Purpose:** determine whether trusted MIG bursts can be converted into a bounded candidate/cue
working set that efficiently supplies the existing parallel graph fabric **without changing search
semantics**.

**Must not change:** 01R law, `HIT_MAX`, TermGen law, Top-K law, 02M law, relation law, LM-06 law.

**Planned metrics:**

```text
ddr_bytes_per_candidate
ddr_bytes_per_query
beats_per_query
candidates_per_query
wavefront_fill_cycles
memory_wait_fraction
jobs_per_cycle_during_wave
record conservation
data mismatch
```

**Explicitly:** `lane_util >= 80%` is **NOT** a universal DDR-wavefront hard gate. It belongs to the
synthetic/local scheduler capacity experiment (`feedback.md` §5, which itself calls it "not a
scientific law, but a useful engineering gate"). A memory-efficient system may have a lower average
lane duty factor and still be superior.

Gate contract source: `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`.

---

## 12. LM06-WM-00 … LM06-WM-04 — PLANNED / BLOCKED

Never call this "move LM06 to DDR". The persistent weights are already in DDR. This is a
**working-set** research line.

### LM06-WM-00 (BLOCKED by `human_reopen`; wavefront characterization is DONE_ENG PASS_NARROW)

**One unknown:** can a bounded / ping-pong LM working-set implementation remain **bit-exact** with
frozen LM-06?

```text
CONTROL   = frozen LM-06
CANDIDATE = working-set reduced LM-06
```

**Equivalence required:** same initial weights, same input, same arithmetic, same forward
result/fold, same update result/fold, same persist/reload semantics. **No semantic-law change.**

### Ladder (only after WM-00 equivalence)

| rung | BRAM target |
|------|------------:|
| LM06-WM-01 | ≤ 96 |
| LM06-WM-02 | ≤ 64 |
| LM06-WM-03 | ≤ 48 |
| LM06-WM-04 | ≤ 32 |

This is a **measurement ladder, not a requirement to reach 32.**

Record at **every** rung: BRAM, LUT, FF, LUTRAM, DSP, WNS, TNS, DDR read traffic, DDR write traffic,
stall fraction, forward latency, training-step latency where applicable, bit-exactness.

**Stop rule:** stop at the best justified Pareto point. 64 tiles exact with good timing beats 48
tiles with collapsed traffic or negative WNS. Do not force 32 because the roadmap contains "32".

---

## 13. Training traffic

Inference and training have different DDR shapes and must never share an estimate.

```text
INFERENCE
DDR read -> tile -> compute

TRAINING
DDR read weights -> tile -> compute/update -> dirty tile -> coalesced DDR writeback
```

Do not estimate training throughput from read-only bandwidth. Future work should investigate dirty
tracking, coalesced writeback, and burst writeback **before** per-weight DDR writes.
**Planning, not PASS evidence.**

---

## 14. 01R / 02M memory migration rule

Physical memory migration must not silently retune semantic or retrieval law.

- **01R:** do not change Hamming authority, `HIT_MAX`, MIH semantics, or candidate acceptance
  semantics in the same experiment as a memory migration.
- **02M:** do not change binding law, episode retrieval semantics, or teacher-off behaviour in the
  same experiment as a memory migration.

Memory migration and law retuning are **separate experiments** (HS-25, one unknown).

Contracts: `docs/contracts/A7-EAM-01R.md`, `docs/contracts/A7-EAM-02M.md`.

---

## 15. HNSW status

```text
HNSW = RESEARCH_ALLOWED, DATAPATH_NOT_APPROVED
```

Do **not** promote HNSW because `M = 16` happens to match 16 PEs. Sixteen lanes prove parallel
Hamming capability, not HNSW system fitness — that is a numeric coincidence, not evidence.

HNSW may open **only if** measured 01R + DDR scaling shows a real candidates/query, DDR bytes/query,
or latency problem. Characterize 01R-only at scale first (256 → 4k → 16k → 65k, frozen `HIT_MAX`).

Possible future comparison: **A** = 01R only, **B** = HNSW only, **C** = 01R → HNSW. Quality gate
first: promote only if recall ≥ baseline **and** fewer candidates **and** fewer DDR bytes **and**
timing PASS. Otherwise `HNSW_REJECTED`.

HNSW must never become relation authority or host-side winner authority.

Source: `results/A7-NATIVE-GRAPH/STATUS/PLAN_KDENSE_20260822.md` §1 RQ5 / §4 Phase E.

---

## 16. Throughput claim hygiene

```text
on-chip candidate-score ceiling  !=  sustained end-to-end graph throughput
```

`16 lanes × 100 MHz = 1.6 G candidate-scores/s` is a **local ideal compute ceiling under II = 1
assumptions**. It is not system throughput and must never be reported as such.

Real system reporting must account for: DDR delivery, candidate production (TermGen), bank
conflicts, queue occupancy, frontier behaviour, Top-K, and LM phase sharing.

---

## 17. Scale doctrine

Parameter count and memory capacity are separate axes (HS-21).

Desired scaling behaviour:

```text
parameter count   -> primarily DDR capacity and DDR traffic
working-set size  -> bounded BRAM
compute           -> fixed / shared PE and MAC machinery
```

803k → 1.5M parameters is a **possible future scalability consequence**, **not** a Native V1 gate.
Do not claim 1.5M works until it is evidenced.

---

## 18. Encoder research status

```text
ENCODER RESEARCH STATUS: OPEN / PARKED — CURRENT NEXT: see encoder authority
```

Encoder authority lives in its own lane: `MUST_READ_UNBLOCK_H5.md`,
`results/A7-EAM-03E/MUST_READ_UNBLOCK_H5.md`, `results/A7-EAM-03E/final.md`.

The Masterplan does **not** carry the encoder's next step as graph-lane authority, does not
re-diagnose it, and does not invent a new encoder experiment. A collapsed or partial encoder must
never be glued into a graph PASS by renaming (HS-20, `15_CURSOR_BLUEPRINT_LOOP.md` §5).

---

## 19. Evidence label vocabulary

Every quantitative claim in this package carries exactly one of:

```text
BOARD | POST_ROUTE | OOC | MIG_XSIM | XSIM | ENGINEERING_ESTIMATE | HISTORICAL_ESTIMATE
```

Sub-classes used by the archives and preserved here: `BOARD_MIG`, `POST_ROUTE_SOC`,
`POST_ROUTE_PROXY`, `POST_ROUTE_FIT_LIMIT`, `OOC_POST_ROUTE`, `BOARD_UART_STUB`,
`BOARD_UART_LM_PATH_PROBE`, `BOARD_UART_SEMANTIC_LIMIT`, `HARNESS`, `CHECKLIST_MAP`, `DOC`,
`ABSENT` / `LIMIT`.

Never merge classes:

```text
FITS != RUNS != TRAINS != CONVERGES != USEFUL
XSIM != BOARD
MIG_XSIM != BOARD_MIG
POST_ROUTE != FUNCTIONAL_INTEGRATION
HARNESS != HS-02
```

---

## 20. Status table

Status vocabulary is restricted to:
`PASS | PASS_NARROW | DONE_ENG | LIMIT | OPEN | BLOCKED | NOT_EVIDENCED`.
No status is inferred from an adjacent milestone.

| Subsystem | Current status | Evidence class | Canonical artifact | Still open |
|-----------|----------------|----------------|--------------------|------------|
| LM-06 frozen routed control (37,555 LUT / 35,864 FF / 132 BRAM / 154 DSP) | DONE_ENG | POST_ROUTE | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/frozen_lm06_utilization_route.rpt` | participation in the Native answer path (HS-22) |
| LM-06 weight fabric in SoC (BRAM 64, WNS +0.365) | PASS_NARROW | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/LM06-SOC/AUDIT_lm06_soc_path.md` | `u_a` absent at that cut; not board-probed |
| LM-06 `u_a` + weight fabric in SoC (BRAM 128, WNS +0.257) | PASS_NARROW | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/LM06-UA/AUDIT_lm06_ua_core.md` | TinyGPT / DSP core absent |
| LM-06 final answer path (HS-22) | LIMIT | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` | additive 264 > 135; no answer-path SoC bit |
| 01R router (frozen; 56 BRAM) | DONE_ENG | POST_ROUTE (frozen SHA MATCH) | `docs/contracts/A7-EAM-01R.md` | scale ladder traffic unmeasured |
| 02M episodic memory (frozen; 52 BRAM) | DONE_ENG | POST_ROUTE (frozen SHA MATCH) | `docs/contracts/A7-EAM-02M.md` | DDR-backed episode store on board |
| A0.3 / encoder lane | OPEN | BOARD (arithmetic exact) + parked research | `results/A7-EAM-03E/MUST_READ_UNBLOCK_H5.md` | encoder geometry; parked, not graph-lane authority |
| Exact global Top-8 | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-TOPK/closeout.md` | silicon Top-K |
| Lossless flow control | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-FLOW/closeout.md` | silicon lossless proof |
| Wide dispatch (16-way) | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-WIDE/AUDIT_ng06_wide_sci_r3.md` | utilisation under varied ready patterns |
| Query/path epochs, stale drop | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-EPOCH/AUDIT_ng06_epoch.md` | board behaviour |
| TermGen (4 families exact, n=32, DSP 0) | DONE_ENG | XSIM + OOC | `results/A7-NATIVE-GRAPH/TERMGEN/AUDIT_termgen.md` | complete candidate throughput claim |
| PERFMON counters | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/PERFMON/AUDIT_perfmon.md` | per-lane counters on the MIG feed path |
| MIG XSim (`mig_h_rival`) | PASS_NARROW | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-RIVAL/AUDIT_mig_h_rival.md` | silicon MIG |
| MIG board (`mig_board_r2`) | DONE_ENG | BOARD_MIG | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_mig_board_r2.md` | 16/16 silicon grid; quarantine superseded |
| MIG board (`mig_board` legacy) | PASS_NARROW | BOARD_MIG | `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md` | pre-metric rows quarantined only |
| MIG-METRIC-00 measurement integrity | PASS | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` | sweep breadth: 2 of 16 burst × outstanding cells; no degree axis |
| BRAM working memory WM-00 (lossless; BRAM 0) | DONE_ENG | XSIM | `results/A7-NATIVE-GRAPH/BRAM-WM-00/AUDIT_bram_wm_00.md` | §45 `BRAM_WORKING_MEMORY_ARCH_PASS` not declared |
| WM-00 OOC timing (WNS +0.069, TNS 0; CONTROL −290.499) | PASS_NARROW | OOC_POST_ROUTE | `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/AUDIT_wm00_timing.md` | SoC-integrated WM timing |
| BRAM ownership post-route report | PASS_NARROW | POST_ROUTE | `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` | integrate_fit cut only — see `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` |
| BRAM capacity co-fit (132/135, WNS +0.586) | PASS_NARROW | POST_ROUTE_PROXY | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/AUDIT_bram_consolidate.md` | soft ≤130 not met; HS-22 open |
| Integrated SoC fit (PE 16 fabric, WNS +0.952) | PASS_NARROW | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/INTEGRATE/AUDIT_integrate_fit_soc.md` | LM-06 weights absent on that bit; blind exam deferred |
| DDR wavefront characterization | DONE_ENG PASS_NARROW | MIG_XSIM_WAVEFRONT | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_ddr_wavefront_00.md` | no throughput win; board class absent; saturating occupancy unmeasured |
| LM-06 working-set reduction (`lm06_wm_00`) | DONE_ENG PASS_NARROW | LM06_WM_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_lm06_wm_00.md` | bit-exact vs frozen CONTROL; ladder BLOCKED until human re-open |
| BRAM phase ownership (`bram_owner_00`) | BLOCKED | — | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md` | blocked by LM06-WM winner |
| Teacher-off framing (UART) | PASS_NARROW | BOARD_UART_STUB | `results/A7-NATIVE-GRAPH/TEACHER_OFF/AUDIT_teacher_off.md` | not semantic HS-02 |
| Teacher-off semantic retrieval (HS-02) | OPEN | BOARD_UART_SEMANTIC_LIMIT | `results/A7-NATIVE-GRAPH/HS02-SEMANTIC/AUDIT_hs02_semantic_evidence.md` | live board semantic exam with held-out wording |
| 800k semantic scale | NOT_EVIDENCED | ABSENT | `results/A7-NATIVE-GRAPH/STATUS/AUDIT_section14.md` | bytes/query and candidates/query at 800k |
| Native V1 `NATIVE_V1_MINI_AI_BOARD_PASS` | NOT_EVIDENCED | CHECKLIST_MAP | `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md` | human declares only after every required box is PASS |

---

## 21. Do not overclaim

Forbidden unless the evidence explicitly supports it:

```text
Native V1 BOARD_PASS
16-PE DDR feed BOARD_PASS
LM06-WM PASS
phase sharing PASS
800k semantic scale PASS
HNSW approved
teacher-off semantic PASS
```

AI does not declare `NATIVE_V1_MINI_AI_BOARD_PASS`. A human declares it, and only after
`14_FINAL_ACCEPTANCE_CHECKLIST.md` is fully evidenced on disk.

---

## 22. feedback.md + BRAM_WORKING_MEMORY_SPEC reconciliation

Design-input audits (`feedback.md` 2026-08-21, `BRAM_WORKING_MEMORY_SPEC.md`) remain valid for
**intent and measurement requirements** but their §26 status summary and some queue assumptions are
**stale** relative to 2026-08-22 evidence.

**Navigation hub:** `results/A7-NATIVE-GRAPH/STATUS/COMPLIANCE_INDEX.md`

**Live maps (feedback/SPEC ↔ Masterplan V2 ↔ closeouts):**

| Document | Scope |
|----------|-------|
| `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` | Combined executive map, R0–R11, conflicts |
| `FEEDBACK_MD_COMPLIANCE.md` | feedback.md §1–§26 section matrix |
| `BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md` | SPEC §0–§45 section matrix |

Rule: when feedback/SPEC phrasing conflicts with this file or `LOOP_STATE.json`, **evidence and
Masterplan V2 win** — document the conflict; do not silently reconcile.
