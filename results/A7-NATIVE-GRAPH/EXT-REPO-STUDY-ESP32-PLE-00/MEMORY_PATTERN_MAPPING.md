# MEMORY_PATTERN_MAPPING — EXT-REPO-STUDY-ESP32-PLE-00

**Status:** ARCHITECTURAL INTERPRETATION — not a Master Blueprint modification.

**Authority check:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/08_MEMORY_ARCHITECTURE.md` §2–3 already
expresses DDR persistent / BRAM active working set / LUTRAM ultra-hot. This document refines
interpretation with external precedent; it does **not** claim novelty.

---

## 1. External three-tier model (observed)

| Tier | Access pattern | External placement | Source |
|------|----------------|-------------------|--------|
| CORE | Dense random, every token | Internal SRAM (planning); flash XIP (deploy) | `src/budget.py` |
| STREAM | Dense sequential full scan | Off-chip bandwidth-bound | `src/budget.py` |
| TABLE | Sparse one row per token | Flash mmap | `src/budget.py` |

---

## 2. Native AI hierarchy (unchanged authority)

```text
DDR   — persistent large state
BRAM  — bounded ACTIVE WORKING SET
LUTRAM/FF — ultra-hot control
```

Source: `08_MEMORY_ARCHITECTURE.md`, `00_CURRENT_AUTHORITY.md` §5.

---

## 3. Proposed Native access-pattern subclasses (interpretation only)

### DDR class A: SEQUENTIAL STREAM

**Pattern:** Large, predictable, burst-coalescable traffic.

| Native candidate | External analogue | Mapping |
|------------------|-------------------|---------|
| LM weight tiles (DDR→BRAM) | Stream tier (head scan) | Both sequential burst-friendly; Native already tiles |
| Bulk checkpoint / coalesced writeback | — | Native learning path (future measure) |
| Contiguous cue blocks | — | DDR-WAVEFRONT ping-pong cue fetch |

**Verdict:** **ALREADY PRESENT** in blueprint + measured (MIG-METRIC-00, mig_board_r2).

### DDR class B: SPARSE / RANDOM

**Pattern:** Large capacity, few bytes touched per query, indexed access.

| Native candidate | External analogue | Mapping |
|------------------|-------------------|---------|
| Graph metadata | — | Native-specific |
| Episode records | — | Native-specific |
| Relation records | — | Native-specific |
| Survivor NodeRecords (post-Top-K) | PLE table row | **Pattern rhyme only** — different law |
| HNSW frontier (research) | Random flash row bench | Methodology support, not datapath approval |

**Verdict:** Doctrine supports two-stage fetch (`08` §7); **random DDR metadata latency not yet measured** on Arty.

### BRAM: ACTIVE WORKING SET

| Native candidate | External analogue | Mapping |
|------------------|-------------------|---------|
| Active LM tile | Staged head buffer (concept) | Stage once, reuse — **lm06_wm_00** XSim |
| Activation tile | PSRAM scratch/KV | Phase-local bounded state |
| Graph candidate wave | — | DDR-WAVEFRONT-00 |
| Frontier / Top-K | — | NG-02/06 evidence |
| Pending updates | — | Learning combine cache |

**Verdict:** **ALREADY PRESENT**. External repo reinforces staging principle; does not solve 132-tile integration.

### LUTRAM / FF: ULTRA-HOT

| Native candidate | External analogue | Mapping |
|------------------|-------------------|---------|
| Queue heads, tags, valid, owner, epoch | Dual-core head row flags, small control | Control-plane only |
| Counters (MIG metric_clear) | — | Native-specific telemetry |
| Cue ping-pong bank select | — | ddr_wavefront_00 |

**Verdict:** **ALREADY PRESENT** in wavefront + ownership doctrine.

---

## 4. Collapse warnings (do not transfer)

| Forbidden collapse | Why |
|--------------------|-----|
| ESP32 PSRAM = Arty BRAM | Capacity, bandwidth, addressing differ |
| Flash mmap = MIG DDR | XIP cache ≠ explicit AXI scheduler |
| PLE table = graph NodeRecord | Model law change vs retrieval record |
| 28.9M params = Native capability | Stored count ≠ semantic/compute capability |

---

## 5. Recommended future metrics (dimensions only)

Do not invent values. Measure when gates open:

```text
ddr_bytes_per_query
ddr_bytes_per_candidate
ddr_bytes_per_useful_survivor
metadata_bytes_per_query
random_transactions_per_query
sequential_bytes_per_query
reuse_distance (tiles, cues)
```

Cross-reference: `08_MEMORY_ARCHITECTURE.md` §6 (candidate count, bytes read, bursts, cache hit).

---

## 6. Relation to DDR-WAVEFRONT-00

External precedent supports:

```text
large backing → fetch subset → stage fast → reuse → defer full fetch
```

Native path (planned, XSim PASS_NARROW only):

```text
DDR cue plane → bounded buffer → 16 PE wave → Top-K → survivor metadata
```

**Classification:** TRANSFERABLE_PATTERN + ENGINEERING_INFERENCE. **Not** Native evidence.

---

## 7. Relation to LM06-WM

| Statement | Status |
|-----------|--------|
| Persistent weights in slower memory | **NATIVE_AI_OBSERVED** — already DDR |
| Bounded compute-active representation in fast memory | **TRANSFERABLE_PATTERN** — lm06_wm_00 goal |
| External repo solves BRAM integration | **FALSE** — NOT_TRANSFERABLE |
