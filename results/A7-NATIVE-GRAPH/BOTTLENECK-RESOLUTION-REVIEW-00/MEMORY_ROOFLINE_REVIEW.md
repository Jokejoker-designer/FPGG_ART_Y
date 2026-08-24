# MEMORY_ROOFLINE_REVIEW — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Reviewer role:** a7-memory-roofline-reviewer (via `a7-ng-memory-arch`)  
**External basis:** Williams–Waterman–Patterson roofline — classified **EXTERNAL_THEORY**; adapted, not copied.

---

## 1. Primary hypothesis (§2) — coupled BRAM + DDR optimization

**Verdict: ACCEPT (AMEND)**

| Sub-claim | Verdict | Evidence |
|-----------|---------|----------|
| BRAM and DDR must be co-designed for V1 fit | **ACCEPT** | 243/260/264 FALSIFIED; ~0.44 cand/cyc plateau |
| They are one knob | **REJECT** | DDR delivery WS ≤2 RAMB18; LM-06 = 132 tiles (`DDR-WAVEFRONT CLOSEOUT`) |
| Minimize memory waiting subject to BRAM≤135 | **ACCEPT** | `memory_wait_fraction` 81–99%; BRAM binding |
| Cut BRAM blindly → DDR thrashing | **ACCEPT** | Doctrine + WM-00 struck inference |

**Amended statement:** Native V1 is a **two-domain** constrained problem:

```text
Domain A (graph delivery):  minimize B_query / maximize R_cand
                            subject to exactness + global Top-K law

Domain B (LM working set): minimize B_lm tiles
                            subject to bit-exact LM-06 + timed refill

Coupling occurs at phase schedule (BRAM-OWNER-00) and total B_peak,
not at sharing one ping-pong buffer between graph cues and u_w tiles.
```

---

## 2. Roofline adaptation for this FPGA

### Operational intensity

```text
I = useful_scoring_ops / DDR_bytes_moved
```

**Today:** only the **feed probe** closes the denominator (1024 B / 64 candidates). Numerator is implicit (64 popcount/XOR ops) — **not instrumented** on integrated graph path.

### Attainable candidate rate

```text
R_candidate ≤ min(R_PE_capacity, B_sustainable / β_candidate)
```

| Variable | Mapped value | Class | Notes |
|----------|-------------|-------|-------|
| `R_PE_capacity` | 16 lanes × 1 emit/cycle = 16/cyc peak | MIG_XSIM_WAVEFRONT | Width proved |
| `B_sustainable` | ~0.444 beats/cyc × 16 B ≈ 7.1 B/cyc @ ui_clk | BOARD_MIG / MIG_XSIM | Sequential consumer |
| `β_candidate` | **16 B** measured | MIG_XSIM_WAVEFRONT | Full NodeRecordV1 |
| `R_sustained` | **~0.441–0.444 cand/cyc** | MIG_XSIM_WAVEFRONT | **At roof** — PE not the binder |

**Conclusion:** Adding PE lanes without reducing `β_candidate` or raising `B_sustainable` is **useless** — measured, not hypothetical.

---

## 3. eta_beat metric (proposal §1)

**Verdict: AMEND**

Valid as **pop-or-stall duty cycle** on the MIG feed probe when defined as `pe_busy/(pe_stall+pe_busy)`.

**REJECT** as:
- universal DDR link efficiency  
- substitute for `recs_per_cyc`  
- proof that starvation is solved (plateau at ~0.556 stall persists)

For burst=16/out=2: `eta_beat ≈ 0.448` matches `64/144 ≈ 0.444` beat delivery — consistent at best cells.

---

## 4. minimum_stage1_descriptor_bits (proposal §5)

### NodeRecordV1 logical layout (frozen)

| Field | Bits | Required for stage-1? |
|-------|-----:|----------------------|
| `node_id` | 32 | **YES** — identity, tie-break |
| `cue` | 32 | **YES** — stored cue (TermGen uses 64b bus) |
| `confidence` | 16 | **MAYBE** — if per-node prior in law |
| `node_type`, `topic_id` | 32 | **NO** for current TermGen stage-1 XOR |
| `degree_sat`, `version` | 16 | **NO** for stage-1 score |

### TermGen stage-1 consumption

Stage-1 XOR/ROTL on **64b `node_cue`** + broadcast query bags. Wavefront currently wires `{cue,cue}` replication to fill 64b — **wiring artifact** (CLOSEOUT L7), not law proof. `learned_prior_i` is **broadcast**, not per-node DDR field today.

**Human correction (2026-08-22): minimum stage-1 descriptor is NOT YET FROZEN.**

| Tier | Bits | Status |
|------|-----:|--------|
| Known lower bound | `node_id` 32 + lawful `node_cue` 64 = **96** | **KNOWN** |
| If per-node `learned_prior` lawful | +8 = **104** | **OPEN** — `DESCRIPTOR-CONTRACT-00` before SOA |
| Full NodeRecordV1 | **128** | Current measured path (16 B/cand) |

| Descriptor option | Bytes aligned | Law fidelity |
|-------------------|--------------:|--------------|
| Prune / dispatch only | 8 | **NOT** TermGen-complete |
| Lower bound (known) | 12–16 | Law-correct if prior resolved |
| Full NodeRecordV1 | 16 | Measured today |

**REJECT** assuming 8 B is sufficient for first-stage **semantic** scoring without descriptor-contract audit.

**expected bytes/query (64 candidates, stage-1 only):**

| Option | B_query |
|--------|--------:|
| Current (16 B/cand) | **1024 B** (measured) |
| 8 B compact cue plane | **512 B** (not measured; requires SOA + schema) |
| 12 B packed 96b | **768 B** (theoretical) |

---

## 5. DDR-CUE-SOA-00 (proposal §7)

**Verdict: AMEND** — research direction valid; gate not ready.

| Criterion | Status |
|-----------|--------|
| Problem alignment (16 B cold fetch) | YES |
| feedback §10 shard / locality | YES |
| Measured byte reduction | **NO** |
| `record_schema_freeze` complete | **PARTIAL** (`mem_schema_v1` DONE; repo-wide OPEN) |
| Global Top-K before survivor metadata | **REQUIRED** (carried_risk_r1) |
| Board evidence | **NO** |

**Dependencies (ordered):**

1. `record_schema_freeze` (doc + golden round-trip)  
2. `WF-GLOBAL-TOPK-00`  
3. Preregister `ddr_bytes_per_candidate` target + Recall@K oracle  
4. XSim then optional board replication  

**Literature:** Besta et al. FPGA graph survey, Dynamic-ACTS locality — **TRANSFERABLE_METHOD** / **EXTERNAL_THEORY**. Do not import HBM assumptions or host-side query sorting.

---

## 6. Little's Law / outstanding (proposal §11)

```text
N_outstanding ≈ ceil(B_target × L / S)
bytes_in_flight ≈ B_target × L
```

| Observation | Implication |
|-------------|-------------|
| Grid swept out ∈ {1,2,4,8}; RTL `MAX_OUT=8` | At ceiling |
| Plateau stall ~0.556 across burst≥4 configs | **Near saturation** of this probe |
| Sustained rate stuck ~0.44 cand/cyc | Beat delivery bound, not under-filled queue |

**Verdict:** Current outstanding structure is **at or above** marginal requirement for this sequential 64-record probe. **REJECT** "raise outstanding forever" without exporting `in_flight`, raising `MAX_OUT`, and changing access pattern.

---

## 7. Double buffering (proposal §10)

**PRESERVED:** `T_refill ≤ T_compute_on_other_buffer` required for stall-free ping-pong.

| Path | Overlap evidenced? |
|------|-------------------|
| Graph cue ping-pong | **PARTIAL** — XSim only; burst≥4 reduces `swap_count` 64→2 |
| LM WM timed refill | **NO** — Arm B zero-latency functional |
| "Two buffers exist" ⇒ hidden latency | **REJECT** |

---

## 8. Memory arbitration (proposal §24)

**Hypothesis: phase-exclusive first** — **ACCEPT (AMEND)**

Fine-grained GRAPH+LM interleaving **not supported** by evidence (243-tile falsification, MIG burst locality). Classify STREAM vs SPARSE **after** global Top-K reduction.

---

## 9. External sources

| Source | Classification |
|--------|----------------|
| Williams roofline | EXTERNAL_THEORY |
| Besta FPGA graph survey | EXTERNAL_THEORY |
| Dynamic-ACTS / partitioning | TRANSFERABLE_METHOD |
| Reuse-distance / MRC | EXTERNAL_THEORY |
| Little's Law MLP | EXTERNAL_THEORY |
| MIG-BOARD-R2 grid | NATIVE_AI_MEASURED_DERIVED |
| WAVEFRONT 0.441 vs 0.444 | NATIVE_AI_MEASURED_DERIVED |
