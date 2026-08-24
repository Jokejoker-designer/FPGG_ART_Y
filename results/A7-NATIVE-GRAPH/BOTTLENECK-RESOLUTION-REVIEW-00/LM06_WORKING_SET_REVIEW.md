# LM06_WORKING_SET_REVIEW — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Reviewer role:** a7-lm-working-set-reviewer (via `a7-ng-memory-arch`)

---

## 1. WM-00 claims — verified

See `CURRENT_STATE_RECONCILIATION.md` §C. Struck inference preserved.

**Additional gap:** `u_a` READ_FIRST vs WRITE_FIRST collision axis **untested** (MUTANT-1 not detected). `NLIVE_ACT=4` preregistered but **not run**.

---

## 2. Reuse-distance / MRC (proposal §8)

### Convention (preregister for ladder)

```text
D_i = number of DISTINCT tile IDs accessed since previous access to tile i
miss_ratio(C) ≈ Pr(D ≥ C)   [document off-by-one at gate open]
MRC(C) = misses / references
```

### Feasibility

| Item | Status |
|------|--------|
| Raw WM counters (`pp_swaps`, `max_live_per_cycle`) | **EXISTS** — LM06-WM-00 logs |
| Tile-address trace streams | **MISSING** |
| MRC histograms per owner | **MISSING** |
| LM DDR bytes per forward+update at enforced NLIVE | **MISSING** (no MIG in WM bench) |

**Verdict:** MRC is **feasible in XSim** with trace sink — **mandatory before ladder rung claims**. Not an LRU implementation requirement; characterization tool only.

### Raw counter observation (not ladder evidence)

```
u_w:    pp_swaps=37,745;   max_live/cycle=1
u_a:    pp_swaps=704,580; max_live/cycle=2
u_snap: pp_swaps=144;     max_live/cycle=2
```

---

## 3. Working-set traffic equations (proposal §9)

| Equation | Measurable today? |
|----------|-------------------|
| Graph `ddr_bytes_per_candidate` | **YES** (16 B) |
| LM `N_refill`, `N_dirty` at synthesizable NLIVE | **NO** |
| `DDR_read_bytes(C,L)` for LM | **NO** |
| `T_mem(C,L)` model ranking | **PARTIAL** (graph B_sust only) |

---

## 4. PROPOSAL C — LM06 reuse-distance Pareto ladder

**Verdict: AMEND**

| Element | Assessment |
|---------|------------|
| Pareto frontier (no arbitrary weights) | **ACCEPT** |
| Stop at first good rung; 32 not mandatory | **ACCEPT** — `AUTHORITY_MEMORY_DOCTRINE.md` |
| Falsify on WNS<0 or DDR stall explosion | **ACCEPT** |
| Bit-exact prerequisite | **MET** (WM-00) |
| Fixed 96/64/48/32 as predetermined cuts | **AMEND** — not trace-derived |

---

## 5. Fixed ladder vs dynamic targets (proposal §13)

**Recommendation: RECOMMEND_MASTERPLAN_AMENDMENT** (retain rung **labels** as ceilings)

| Position | Rationale |
|----------|-----------|
| **KEEP_EXISTING_96_64_48_32** as reporting checkpoints | Already in LOOP_STATE, doctrine, compliance gap G-P3-02 |
| **AMEND** execution semantics | Each rung must publish **per-owner NLIVE + synthesized tiles + DDR stall + bit-exact** |
| **ADD** near-boundary probes | e.g. 128, 124, 120, 112 before jumping to 96 — if MRC shows only 8–16 tiles need shedding |
| **DO NOT** replace labels until `lm06_wm_01` produces MRC | Human re-open still required |

**Q1 answer:** Dynamic target **conflicts with fixed ladder as sole plan** — amend masterplan text, do not silently edit LOOP_STATE.

**Q2 answer:** Amend **documentation** before human re-open; keep queue ids `lm06_wm_ladder` / `lm06_wm_01..04`.

---

## 6. Which owner to cut first? (proposal §15)

Marginal metrics `ρ_bytes`, `ρ_cycles` — **not measurable today**. Evidence-based **prior** until traces exist:

| Priority | Owner | Rationale |
|----------|-------|-----------|
| **1st** | `u_w` (64 tiles) | Board-bounded weight staging exists; `live_pair_events=0`; MEM-00 ranks W shrink first |
| **2nd** | `u_a` (66 tiles) | Largest owner; highest churn; NLIVE=4 path not exercised |
| **3rd** | `u_snap` (2 tiles) | Negligible BRAM leverage |

**REJECT** assuming `u_a` first without trace — hypothesis only.

**Separate lever:** phase-share `u_a` with graph (`bram_owner_00`) — not a ladder tile shave.

---

## 7. BRAM fit equation (proposal §12)

```text
B_total = B_always + max(B_graph_phase, B_lm_phase)
```

| Term | Evidence |
|------|----------|
| `B_lm ≈ 132` | POST_ROUTE measured |
| `max(B_graph, B_lm)` vs sum | **Sound** for phase-exclusive model |
| `B_always` (encoder 3, MIG, FIFOs, debug) | **INCOMPLETE** — `BRAM_OWNERSHIP_REPORT_V1_DRAFT` |
| 01R 56 + 02M 52 on-chip naive | **FALSIFIED** — DDR-back required |
| Soft target ≤130 | **NOT MET** (132 co-fit proxy) |

**Q6 answer:** Equation is **realistic planning model** but **insufficient for ship proof** until lifetimes measured on integrated top and `bram_owner_00` evidenced.

### Always-on consumers (draft completeness)

| Block | BRAM | Status |
|-------|-----:|--------|
| LM-06 u_w/u_a/u_snap | 132 | measured |
| 01R router | 56 | frozen separate bit — integration TBD |
| 02M episodic | 52 | DDR-backed in MEM-01/02 |
| A0.3 encoder | 3 | concurrent vs phased **unresolved** |
| NG-02R FIFOs | TBD | OPEN |
| MIG IP internal | partial | SoC enum missing |
| Graph delivery WS | ≤2 tiles | architectural, not post-route |

---

## 8. Pareto dimensions (proposal §14)

Measure per candidate: BRAM, LUT, FF, LUTRAM, DSP, WNS, TNS, DDR_read/write per token, miss ratio, dirty eviction, memory stall fraction, forward/training latency, bit-exactness.

**Hard reject:** bit-exact FAIL, WNS<0, TNS≠0, law change, unbounded queue, data loss.

**Do not** create weighted score without human-approved weights.

---

## 9. PROPOSAL D cross-reference

BRAM-OWNER-00 sequence — see `HS22_INTEGRATION_REVIEW.md`. LM ladder should complete **or** establish Pareto winner **before** owner FSM silicon proof, per doctrine ordering.
