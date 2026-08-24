# CHANGELOG — Masterplan V2 revision of `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/`

**Date:** 2026-08-22 · **Type:** documentation / authority reconciliation only
**Gate:** MASTERPLAN-V2 · **Board runs:** none · **RTL changes:** none · **Gate ticks:** none

Principle applied throughout:

```text
PRESERVE VALID ARCHITECTURE
PATCH STALE EXECUTION STATE
ADD CURRENT EVIDENCE DELTA
```

No blueprint section that was still correct was rewritten. No frozen artifact, raw result, historical
closeout, `LOOP_STATE.json` or `DISPATCH_LOG.jsonl` was modified by this work — see
`MASTERPLAN_V2_AUDIT.md` §3 for the mechanical proof.

---

## Files created

### `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md` (new)

The evidence delta between the pre-execution blueprint and what the repository can prove today.

| § | Content | Why it was needed |
|---|---------|-------------------|
| 1 | Authority order; "Masterplan defines architecture / LOOP_STATE defines live execution / evidence defines truth"; chat memory and historical next-instructions declared non-authoritative | The package had no stated precedence rule, so stale roadmap text could be read as a live command |
| 2 | Required correction box — 6 corrections | The six specific errors that were propagating through the package |
| 3 | LM-06 memory truth: `u_a` 66 / `u_w` 64 / `u_snap` 2 = working machinery | Persistent weights were already DDR-resident; "move 802,816 weights to DDR" described a migration that had already happened |
| 4 | Naive BRAM stacking FALSIFIED at 243 / 260 / 264 vs 135 | It was being treated as an open estimate rather than a measured architectural FAIL |
| 5 | Final memory hierarchy (DDR / BRAM / LUTRAM-FF / compute) | The old three-line principle did not distinguish LM-phase from GRAPH-phase working sets |
| 6 | Phase sharing as ownership handover; one bank / one writer / one cycle; marked FUTURE INDEPENDENT EXPERIMENT | The package implied simultaneous sharing was viable; the locked doctrine forbids it |
| 7 | Ping-pong / working-set doctrine; rejects per-weight DDR access and "zero-BRAM LM" | The objective is bounded, not zero |
| 8 | Current MIG evidence: board rows, per-run deltas, and the evidence-lineage note | Board and revised-RTL evidence were at risk of being merged |
| 9 | DDR delivery vs capacity; 1.33 GB/s theoretical raw; 16 lanes ≠ 16 records/cycle | The bottleneck was mis-stated as capacity |
| 10 | Architectural roadmap vs live loop authority kept apart; §10.2 live snapshot; §10.3 session-chaining supersession | LOOP_STATE must remain the single live authority |
| 11 | DDR-WAVEFRONT-00 contract, with an explicit statement that this package endorses no result of it | The contract is stable regardless of outcome; this package verified nothing |
| 12 | LM06-WM-00 equivalence unknown + WM-01…04 ladder as a measurement, not a target | Prevents "move LM06 to DDR" framing and prevents forcing 32 tiles |
| 13 | Training traffic ≠ inference traffic | Training throughput was at risk of being estimated from read-only bandwidth |
| 14 | 01R / 02M migration rule: migration and law retuning are separate experiments | HS-25 isolation |
| 15 | HNSW `RESEARCH_ALLOWED, DATAPATH_NOT_APPROVED`; the `M=16` coincidence rejected | Prevents promotion on a numeric coincidence |
| 16 | Throughput claim hygiene: compute ceiling ≠ system throughput | 1.6 G was quotable as system throughput |
| 17 | Scale doctrine: 803k → 1.5M is a consequence, not a V1 gate | HS-21 |
| 18 | Encoder status OPEN / PARKED, deferred to encoder authority | The graph package must not carry the encoder's next step as its own |
| 19 | Evidence label vocabulary and non-merge rules | Labels were inconsistent across the package |
| 20 | Status table, 27 rows, restricted vocabulary, every artifact path verified to exist | There was no single current-status view |
| 21 | Do-not-overclaim list | Explicit refusal list |

## Files updated

### `README.md`

- **Added** a `CURRENT AUTHORITY` block at the top: architecture = this package; live state = `LOOP_STATE.json`; current evidence = latest audited closeouts; prominent link to `00_CURRENT_AUTHORITY.md`.
- **Added** `CHAT MEMORY IS NOT PROJECT AUTHORITY` and `HISTORICAL NEXT INSTRUCTIONS ARE NON-AUTHORITATIVE`.
- **Corrected** the evidence list: LM-06's 132 tiles labelled working machinery with the `u_a` / `u_w` / `u_snap` split; naive stacking labelled **FALSIFIED** with 260 and 264 added; rows labelled `POST_ROUTE`.
- **Corrected** the encoder line to `OPEN / PARKED`, deferring to encoder authority.
- **Added** `00_CURRENT_AUTHORITY.md` as item 0 of the package map.
- **Added** `XSIM != BOARD`, `MIG_XSIM != BOARD_MIG`, `POST_ROUTE != FUNCTIONAL_INTEGRATION` to core doctrine.
- **Preserved:** target final claim, explicit non-claims, the rest of the package map.

### `02_IMPLEMENTATION_ROADMAP.md`

- **Preserved verbatim** the entire NG-00 → NG-09 → MEM → LM-Q → INT → SCALE → FINAL structure, now under **A. ORIGINAL ARCHITECTURAL MILESTONES**, explicitly declared "not a live queue".
- **Added B. CURRENT COMPLETION / SUPERSESSION MAP** — 29 rows mapping each milestone to status, evidence class, canonical artifact and supersession. Completed and superseded milestones point at evidence instead of instructing reimplementation. Supersessions recorded: NG-02 pair-winner Top-K → NG-02R-TOPK (SEV-0 correctness); NG-03 DDR measurement → DDR-FEED → MIG-RIVAL → MIG-METRIC-00; NG-06 utilisation claims → NG-06R-WIDE + NG-06R-EPOCH.
- **Added C. CURRENT REMAINING DEPENDENCY ROADMAP** — memory chain, semantic/claim chain, the four QUEUED-but-not-dispatchable items, and a research-only section (HNSW, encoder, 1.5M scale).
- No milestone marked PASS beyond what its evidence class supports.

### `08_MEMORY_ARCHITECTURE.md`

- **§1** retitled "naive stacking is FALSIFIED"; added the 260 and 264 measured compositions; added the explicit refusal of `UA128 + full LM06` as a final architecture.
- **§2** replaced the three-line memory principle with the four-tier hierarchy including per-phase BRAM contents; added "bounded, not zero".
- **§4** replaced "audit pending" with the completed audit result and the 2.36 Mbit vs 6.42 Mbit arithmetic; recorded the unresolved `u_w` sizing question.
- **§5** added DDR delivery vs capacity, 1.33 GB/s theoretical raw, the 25.6 GB/s counter-arithmetic, and the labelled engineering direction.
- **§8b** added ping-pong doctrine and its two rejections.
- **§9** rewritten as an ownership-handover FSM with the one-writer invariant, marked a future independent experiment.
- **§9b / §9c** added training-vs-inference traffic and the 01R / 02M migration rule.
- **Preserved:** required integrated layout, episode capacity examples, avoid-full-scan, two-stage fetch, hot-shard strategy, memory integrity gates.

### `11_RESOURCE_CAPACITY_THROUGHPUT.md`

- **Added** a mandatory evidence-label header.
- **§2** labelled `POST_ROUTE`; naive stack marked FALSIFIED with the two later compositions and the co-fit caveat.
- **§4 stale claim removed.** "No PE has been routed yet, so an exact maximum is impossible" is deleted, replaced by a four-row measured table (NG-01 standalone 618 LUT / 411 FF; SoC `u_sc` 1,046 LUT / 1,856 FF for 16 lanes; LM06-SOC 1,048; LM06-UA 1,047) plus whole-SoC context. Derived ≈ 65 LUT per routed lane.
- **§4.2** the 180 / 260 / 400 LUT figures and every table derived from them retained **only** under `HISTORICAL_ESTIMATE`, noting measured cost is ~4× cheaper and that LUT is not the binding constraint.
- **§6** added throughput claim hygiene; 1.6 G labelled a local ideal ceiling under II = 1.
- **§7** restructured into link-level `ENGINEERING_ESTIMATE`, the 1.159 GB/s figure demoted to `HISTORICAL_ESTIMATE`, and a new subsection of current measured integer-only DDR facts including the quarantine and the backpressure-vs-drop rule.
- **§9 / §11** labelled `HISTORICAL_ESTIMATE`; §11 gained the inference-vs-training traffic distinction.
- **§13** bottleneck prediction updated against evidence: BRAM CONFIRMED, DDR delivery CONFIRMED as the active front, LUT/timing DOWNGRADED, LM latency NOT REACHED.

### `12_FAILURE_DECISION_TREE.md`

- **Preserved** branches A–L unchanged.
- **Added** branches M–T: MIG metrics inconsistent → fix measurement integrity before optimizing; MIG clean but service 1-wide → characterize wavefront/buffering, do not add PEs; DDR bytes/query too high → compact cue plane, locality, late metadata fetch; LM + graph BRAM > 135 → do not stack, run working-set audit → equivalence → ladder → ownership; working-set reduction breaks exactness → reject candidate, frozen LM-06 stays CONTROL; phase ownership stale state → fix owner/epoch/dirty/valid; memory migration changed retrieval law → FAIL experiment isolation; HNSW before baseline scaling → reject/defer.

### `13_CURSOR_MASTER_PROMPT.md`

- **Removed** `START NOW WITH AUDIT + NG-00 CONTRACTS, THEN NG-01 16-LANE SCORER` and `FIRST IMPLEMENTATION TARGET: NG-00 through NG-03 only` as live commands; both declared historical.
- **Removed** automatic chaining. Flow is now `IMPLEMENT -> VERIFY -> AUDIT -> CLOSEOUT -> STOP`, with an explicit statement that a PASS does not authorize implementing the next gate in the same session and that Cursor must not chain hardware-law changes automatically.
- **Added** the first rules: read `LOOP_STATE.json`; read `00_CURRENT_AUTHORITY.md`; read the active gate's latest closeout; do only the first OPEN live gate; one unknown.
- **Added** verbatim in meaning: "Masterplan defines architecture. LOOP_STATE defines current live execution. Evidence defines truth."
- **Added** authority order, dispatch law, evidence labels and non-merge rules; updated design principles 1, 5, 6, 7 to the measured memory reality.
- **Added** a recorded supersession: `15_CURSOR_BLUEPRINT_LOOP.md` §2 step 5 is superseded while `LOOP_STATE.session_override.forbid_queue_self_chaining = true`. `15_` itself was not edited.
- **Preserved:** subagent ownership discipline, the on-failure protocol, the NEVER list, the GOAL and the human-declares rule.

### `14_FINAL_ACCEPTANCE_CHECKLIST.md`

**No gate weakened. Additions only.**

- **Header:** every ticked box needs a file-backed artifact and one evidence label, with BOARD class wherever `04_HARDSTOPS.md` requires silicon.
- **Memory:** added persistent LM weights DDR-backed; persistent index DDR-backed where claimed; bounded BRAM working set with declared bound *and* measured occupancy; documented physical BRAM ownership with the seven required columns; no two writers to one physical bank in one cycle; DDR bytes/query measured; candidates/query measured. Added a scope note that the section must describe the *actual final design* and may not be satisfied by a merely planned migration.
- **Teacher-off:** added `host_semantic_cue=0`, `host_winner=0`, `host_episode_address=0`, `host_next_token=0`, `host_weight_writes=0` where the final contract supports them, plus an explicit statement that a UART framing stub or constant flag readback does not satisfy the section.
- **LM-06:** added the required chain `structured Native evidence -> LM-06 active compute path -> FPGA token generation`, with probe / stub / sticky `lm_path` flag / compose marker explicitly insufficient.
- **Claims:** added compute-ceiling-vs-throughput separation and the note that parameter scaling beyond 802,816 is not a V1 gate.

### `10_VALIDATION_AND_EVIDENCE.md` (touched only where lineage required)

- **§1** evidence label list extended to the current vocabulary plus archive sub-classes, with the non-merge rules.
- **§1b added** — board evidence is scoped to its bitstream/RTL revision and is not inherited by a later revision, worked through the `mig_board` → `MIG-METRIC-00` example, plus the quarantine and the backpressure-vs-drop rule.
- **§1c added** — measurement integrity precedes optimization; the cumulative-as-per-run error recorded as FALSIFIED.
- **Preserved:** §2–§11 unchanged.

### `09_LM06_LOWBIT_OPTIMIZATION.md` (touched only where LM-06 memory claims required)

- **§10** upgraded from "run the audit first" to the audit result: the tile split, the staging-buffer arithmetic, the conditional nature of any BRAM saving, the 243 → ~195 best case still over budget, and the conclusion that quantization is not the load-bearing integration lever. Added the ban on "moving 802,816 weights from BRAM to DDR" phrasing.
- **Preserved:** §1–§9 unchanged, including the W4-first ordering and the training warning.

## Files deliberately NOT changed

`01_SYSTEM_BLUEPRINT.md`, `03_MINESWEEPER_TRAINING_GAME.md`, `04_HARDSTOPS.md`,
`05_PARALLEL_AGENT_ENGINE.md`, `06_KNOWLEDGE_GRAPH_AND_ATTENTION.md`,
`07_TEACHER_AUDITOR_PROTOCOL.md`, `15_CURSOR_BLUEPRINT_LOOP.md`,
`RESOURCE_ESTIMATE_SNAPSHOT.txt`, `configs/`, `contracts/`, `templates/`, `references/`, `tools/`.

Their architecture and hard stops remain correct. `RESOURCE_ESTIMATE_SNAPSHOT.txt` is left as a
historical artifact and labelled `HISTORICAL_ESTIMATE` from `11_` §4.2 rather than rewritten. `15_`
is superseded on exactly one point, recorded in `13_` and `00_` rather than edited.

`docs/native_graph/RESOURCE_BUDGET.md` was **not** edited despite carrying an 01R LUT figure (1,452)
that conflicts with the blueprint (1,252) and with its own naive sum. Out of scope; flagged in
`SOURCE_MAP.md` §9.

> **RESOLVED post-task by `a7-ng-orchestrator` (2026-08-22).** Both flags raised in `SOURCE_MAP.md` §9
> were adjudicated and closed:
>
> 1. **01R LUT — flag upheld, typo corrected.** `RESOURCE_BUDGET.md` line 11 changed `1,452` -> `1,252`.
>    Proof is internal to the table: `8,107 + 1,252 + 1,704 + 37,555 = 48,618`, exactly the stated naive
>    sum, whereas `1,452` yields `48,818`. FF (`46,672`) and BRAM (`243`) already reconcile, so LUT was
>    the sole defective cell. Masterplan V2 needed no change — it had the correct figure.
> 2. **SPEC §28 report — flag reversed.** `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md`
>    **does exist** (3,036 B) and carries the required §28 columns for LM-06 (`u_w` 64 / `u_a` 66 /
>    `u_snap` 2), encoder, graph hotset, episode/index banks, MIG buffers and debug. The
>    "still does not exist" line in `STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` was factually
>    wrong and is corrected to **PARTIAL**: the report is scoped to the `integrate_fit` 130-tile cut and
>    omits **router** and **integration FIFOs**. The queued `bram_ownership_report` gate is restated as
>    *extend and re-issue against the final Native V1 cut*, not *create from nothing*. Full-integration
>    claims remain blocked either way.

---

## Events during authoring

### 1. Live queue moved

`LOOP_STATE.json` (11:58:38) and `DISPATCH_LOG.jsonl` (11:59:18) were modified by a **parallel
session** while this revision was being written (blueprint edits ran 11:55:02 – 12:06). That session
closed `ddr_wavefront_00` as DONE_ENG / PASS_NARROW / `MIG_XSIM_WAVEFRONT`.

This task made **no** write to either file (`MASTERPLAN_V2_AUDIT.md` §3.1). The Masterplan endorses
no result of that gate: it was authored against the OPEN state, verified nothing and re-derived no
numbers. `00_` §11 records the live class as a pointer, explicitly not a corroboration, and states
**Not BOARD. Not Native V1.** Downstream gates remain BLOCKED.

### 2. Duplicate dispatch on this documentation gate

A second agent ran the same MASTERPLAN-V2 task concurrently and wrote into the same files. Following
the precedent in `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md` — retain, do
not delete, do not choose the nicer number — its artifacts are preserved as:

```text
CONCURRENT_UNCITED_CHANGELOG.md
CONCURRENT_UNCITED_MASTERPLAN_V2_AUDIT.md
```

**RETAINED, UNCITED.** The two sets converge on the same corrections, evidence classes and refusals,
differing only in depth and in the wavefront framing. Blueprint content was reconciled additively
rather than by reverting the other agent's work. Recorded as a process finding against the
orchestrator, consistent with `PIPELINE_DISPATCH`.
