# Native AI detailed plan — K-Dense scientific method (2026-08-22)

**Skills used:** hypothesis-generation, experimental-design, scientific-critical-thinking  
(vendor `.agents/skills/scientific-agent-skills/`)  
**Goal:** `NATIVE_V1_MINI_AI_BOARD_PASS` (human). Not claimed.  
**Accountable owner:** Anh Quân. AI = PATCH_DRAFT / VERIFY_ONLY.

Hypotheses below are **candidates**, not findings.

---

## 0. Frozen observation (not interpretation)

| Fact | Provenance | Class |
|------|------------|-------|
| GOAL unmet; §14 OPEN | `PROJECT_COMPLETE.md` | EVIDENCE |
| Next in `LOOP_STATE` | `ng06_wide_dispatch` **OPEN** | EVIDENCE (queue) |
| NG-06R-WIDE GATE file | util16=100% starve=0, marker WIDE_XSIM_PASS | EVIDENCE (XSim) |
| Queue vs GATE mismatch | GATE says PASS + next epoch; LOOP still OPEN | **CONFLICTING** |
| P0 Top-K + flow | 100k oracle / lossless XSim + auditor | EVIDENCE (eng.) |
| `integrate_fit` | BRAM 135/135; `u_a_phase_share` FALSIFIED | EVIDENCE (post-route) |
| Teacher-off | pytest harness only | EVIDENCE (not board) |
| Encoder 03E | silicon exact; worst-seed `M_L1` negative; PARKED | EVIDENCE |
| 01R | FROZEN BOARD_PASS; HIT_MAX=8 | EVIDENCE |
| TRAIN-V2 | protocol frozen; not run | EVIDENCE |
| 16 PE Hamming | compact allocator; 1/4/8/16-way ladder | EVIDENCE (XSim) |
| Scale 4k–800k 01R traffic | **not measured** | MISSING |

Product vs blueprint: kernels + two P0 repairs ≈ **25%**. Not 80%.

---

## 1. Research questions (current, not HNSW-first)

**RQ1 (immediate):** Is NG-06R-WIDE closed under the **declared** util≥80% gate, or is LOOP_STATE lag / paper PASS?

**RQ2:** After true wide-dispatch, does query/path **epoch** stop stale expand without permanent semantic kill (HS-06/07)?

**RQ3:** Can one `xc7a100t` bit host graph+LM with BRAM **≤130** without wiping frozen SHA (HS-11)?

**RQ4:** Does a **new** graph/WM law require TRAIN-V2 from zero vs frozen control (same 20/40 facts)?

**RQ5 (later only):** Does HNSW-as-VER reduce DDR bytes/query vs 01R-only **without** recall collapse, on the **same** 64-bit cue?

PICO for RQ5: Population = synthetic Hamming corpus; Intervention = 01R / HNSW / 01R→HNSW; Comparator = 01R-only; Outcome = Recall@K + bytes/query; Time = after 01R scale bag exists.

---

## 2. Candidate hypotheses + rivals (Platt; none proven)

| ID | Candidate | Discriminating prediction | Rival |
|----|-----------|---------------------------|-------|
| H-disp | Compact allocator + N_WAY=16 is enough for HS-09 honesty | util≥80% **and** jobs_per_cycle mode=16 under **varied** ready patterns | Rival: 100% util is one hotset-always-ready pattern (pseudoreplication of cycles) |
| H-epoch | Generation/epoch drop is sufficient reset for working set | DROP_STALE; learned DDR priors survive | Rival: silent kill of live paths (HS-07) |
| H-bram | Phase-share cannot free a tile at full u_a | already FALSIFIED at 135/135 | Rival: shrink shared pool / drop A0.3 from same bit / DDR act spill |
| H-train | New law on old DDR priors confounds attribution | V2 vs control diverge on same 20 facts | Rival: “warm start is fine” |
| H-hnsw | HNSW wins only if 01R candidates/query explode | 01R @65k still tens of candidates → HNSW_REJECTED | Rival: “16 PE ⇒ HNSW fits” (numbers coincidence) |

---

## 3. Design rules (experimental-design)

**Experimental unit:** one **query** (or one independent traffic seed), not one clock cycle.  
100k cycles with sticky `lane_req=all` is **pseudoreplication** if used as “100k queries.”

**Block on:** RNG seed, N_WAY, occupancy, ready sparsity.  
**One unknown per run.** Do not change law + curriculum + HNSW together.  
**Controls:** frozen 01R/02M/LM/A0.3 bits; old graph dump as TRAIN-V2 control.  
**Blind:** teacher=0, no entity/intent/winner/address (HS-02/04).

---

## 4. Ordered work (do in this order)

### Phase A — Close the queue contradiction (this week)

**A1. Auditor `a7-evidence-auditor` on NG-06R-WIDE**  
Unknown: GATE PASS vs LOOP OPEN.  
PASS only if: SHA matches RTL, TB uses `lane_grant_o` not `pop_valid_o`, util measured on **more than one** ready pattern, starve=0.  
If only the always-busy hotset bag → **downgrade** to PASS_NARROW; keep OPEN or add `ng06_wide_stress`.  
If clean → set `ng06_wide_dispatch` DONE_ENG; **next = `ng06_epoch`**.

Skill: scientific-critical-thinking (XSim ≠ board; don’t promote on one traffic).

### Phase B — P1 correctness of time (next)

**B1. `ng06_epoch` + `ng04_stale_event` (one RTL law)**  
Unknown: stale fire ignored iff `fire_epoch != active`; no global learned wipe.  
Bag: 100k mixed epochs; DROP_STALE count; no HS-07 wipe of unrelated priors.  
Then `reset_00` logical generation (BRAM_RESET_RETRAIN_PLAN) — **never** delete LM-06.

**B2. `perfmon` counters** (feedback §21) as **instrumentation**, not a new law.

### Phase C — Memory / fit (blocked on B)

**C1. `mem_schema_v1`** freeze Node/Edge/EpisodeRecordV1 strides.  
**C2. `bram_wm_00`** WM without LM-06.  
**C3. Re-open `integrate_fit`** only with a **new** lever (DDR act spill or drop concurrent A0.3). Phase-share full-66 is **dead**. Target ≤130 tiles, WNS≥0, **new bit**, no SHA overwrite.

### Phase D — TRAIN-V2 (blocked on law freeze + C)

Follow `A7-NATIVE-GRAPH-TRAIN-V2.md` exactly:

```text
OLD model frozen control
RESET learned graph/confidence/edges only
same 20 facts → teacher-off
same 40 facts → teacher-off
Run A mapping → RESET → Run B mapping
```

Plumbing-only (bit-exact Top-K, ping-pong) = **no** retrain.

### Phase E — Retrieval quality at scale (before any HNSW in SoC)

**E1. 01R-only ladder** (frozen 01R, do not retune HIT_MAX): 256 → 4k → 16k → 65k.  
Preregister: Recall@1/8/32, candidates/query, DDR bytes/query, p50/p95.  
If 65k still “tens of candidates” and recall holds → **do not open HNSW**.

**E2. NG-HNSW-00 research only** (if E1 fails the traffic gate)  
Arms A/B/C: 01R | HNSW | 01R→HNSW. Same 64-bit cues. FPGA search or CPU **oracle**, never PC→winner IDs in RELEASE.  
Promote iff recall ≥ baseline **and** fewer candidates **and** fewer DDR bytes **and** timing PASS. Else `HNSW_REJECTED`.  
Insert/HNSW-maintain **not** in TRAIN-V2 first run.

### Phase F — Teacher-off on kit

Harness ≠ exam. After D+E: `teacher=0 external_LLM=0 learn=0 freeze=1` held-out + paraphrase + contradiction on **programmed bit**. Then human §14.

---

## 5. Critical-thinking flags on current claims

| Claim | Grade | Issue |
|-------|-------|--------|
| util16=100% | XSim, possibly one occupancy | Pseudoreplication of cycles |
| “16 lanes ⇒ HNSW” | speculation | Coincidence of M=16 |
| DONE_ENG NG-07…09 | XSim/harness | Not silicon |
| integrate 135/135 WNS+1.23 | timing of **proxy** top | Not a fitted LM+graph SoC |
| Teacher-off PASS | harness | HS-02 not met |

---

## 6. Explicitly not next

- Glue encoder 03E into graph PASS  
- Silent-tune 01R HIT_MAX  
- TRAIN-V2 + HNSW insert together  
- Delete old models when BRAM tight  
- Self BOARD_PASS  
- Load 163 K-Dense **bio** skills into the FPGA loop  

---

## 7. Immediate action (one unknown)

```text
GATE: ng06_wide_dispatch_close
UNKNOWN: is NG-06R-WIDE evidence sufficient to flip LOOP_STATE?
OWNER: a7-evidence-auditor then orchestrator --dispatch
IF PASS → ng06_epoch
IF NARROW → extra ready-sparsity bag, then epoch
```
