# AUDIT — train_v2 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **HARNESS** (not BOARD, not HS-02 silicon, not XSim)  
**GATE:** `train_v2` / `A7-NATIVE-GRAPH-TRAIN-V2`  
**LOOP_STATE:** first OPEN / `next` = `train_v2` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-teacher-protocol` / `PASS` / marker `A7NG_TRAIN_V2_HARNESS_PASS`  
**Refuse rule:** DONE_ENG allow **false** if sold as HS-02 / BOARD / silicon; control dump silently edited; frozen LM/01R/02M/A0.3 SHA drift; Evidence_class mixed with board.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=train_v2
```

---

## Verdict

```text
AUDIT: 3 FINDINGS
result: PASS
allow_loop_done_eng: true
recommended_status: DONE_HARNESS (or DONE_ENG with Evidence_class=HARNESS explicit)
severity_metrics: CONTROL/WARM/V2-A/V2-B top1 0.75/0.50/1.00/0.75 EVIDENCE; forgets_a=true EVIDENCE; control canonical SHA 9E746E3F… intact; frozen LM/01R/02M/A0.3 MATCH; Evidence_class=HARNESS; no BOARD_PASS; not HS-02
```

H_CANDIDATE (TRAIN-V2 from-zero under `a7ng-train-v2` beats warm and ≥ control on preregistered 20-bag top1; Run B forgets A) **SUPPORTED** — **EVIDENCE** (re-derived).  
H_RIVAL (control edited / host BOARD illusion) **partially open on telemetry stubs** (findings) but **did not falsify** attribution metrics or control content.  
**Do not declare BOARD_PASS.** **Do not treat as HS-02 silicon.** **Do not flip LOOP_STATE** (orchestrator only).

---

## Declared scientific frame (graded)

| Slot | Declared (GATE) | Auditor grade |
|------|-----------------|---------------|
| OBSERVATION | law/WM/TermGen change breaks old-state attribution | **EVIDENCE** (contract + harness) |
| UNKNOWN | reset-learned + same 20/40 → V2 ≥ control, ≫ warm? | **Closed YES (harness)** — **EVIDENCE** |
| H_CANDIDATE | from-zero V2 beats warm / ≥ control | **SUPPORTED** — **EVIDENCE** |
| H_RIVAL | harness illusion / control edit | **PARTIAL** (telemetry stubs; control content intact) |
| FALSIFIER | old model edited; frozen overwrite; BOARD self-declare | **Did not fire** on bits/content |
| UNIT | fact bag / query set | **EVIDENCE** (n_q=8 on 20 facts) |
| CONTROL | old dump SHA + frozen bits | **EVIDENCE** with SHA-label caveat (finding #1) |
| METRICS | `METRICS_PREREGISTERED.json` | **EVIDENCE** (thresholds applied to Run A; B paraphrase carve-out disclosed) |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `train_v2` / `a7-ng-teacher-protocol` | **PASS** — DISPATCH_LOG last implementer line |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `train_v2` → `a7-ng-teacher-protocol` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `train_v2` |
| Parent claimed BOARD_PASS / HS-02 | **PASS** — none; GATE/closeout refuse |
| Evidence_class mixed with board/silicon | **PASS** — HARNESS labeled |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Headline numbers (auditor re-derived)

| Arm | Claimed top1 | Artifact | Recalc |
|-----|--------------|----------|--------|
| CONTROL | 0.75 | `control/metrics_20.json` 6/8 | **0.75 MATCH** |
| WARM | 0.50 | `warm_contaminant/metrics_20.json` 4/8 | **0.50 MATCH** |
| V2-A | 1.00 | `run_a/metrics_20.json` 8/8 | **1.00 MATCH** |
| V2-B | 0.75 | `run_b/metrics_20.json` 6/8 | **0.75 MATCH** |

| Check | Claim | Auditor |
|-------|-------|---------|
| Δ vs warm | +0.50 | **1.00 − 0.50 = 0.50 ≥ 0.25** |
| V2 ≥ control | 1.00 ≥ 0.75 | **PASS** |
| forgets_a | true | **Re-run: a_checked=4, a_retained=0 → true** |
| EXPERIMENT_SUMMARY SHA | `32A91009…` | **MATCH** file bytes |
| Control canonical SHA | `9E746E3F…` | **MATCH** `json.dumps(obj, sort_keys=True)` |
| Control **file** SHA | (implied by `control/SHA256.txt`) | **6539605C…** — see finding #1 |
| Frozen LM06/01R/02M/A0.3 | MATCH | **Live rehash MATCH** |

---

## Findings

```
[MAJOR] control/SHA256.txt labels canonical digest as file hash
  where     : results/A7-NATIVE-GRAPH/TRAIN-V2/control/SHA256.txt ;
              python/native_graph/train_v2_harness.py (control_sha = sort_keys compact;
              write uses indent=2)
  claim      : "9E746E3F…  old_model_dump.json" and GATE "Control dump SHA unchanged"
  evidence   : sha256(file bytes)=6539605C…; sha256(canonical JSON)=9E746E3F…;
               tree SHA256.txt correctly lists 6539605C for the file;
               reload→canonical equality holds (content not edited)
  why it matters: a reader running sha256sum on the dump concludes tampering vs the
               advertised control SHA, or trusts the wrong digest as bit-exact freeze
  fix        : write control/SHA256.txt with file-bytes digest; keep canonical digest
               as a separate field (e.g. control_sha_canonical) in EXPERIMENT_SUMMARY
```

```
[MAJOR] teacher_off_telemetry hardwires PE/agent counts; blind packets unused for scores
  where     : results/A7-NATIVE-GRAPH/TRAIN-V2/run_a/teacher_off_telemetry.json ;
              train_v2_harness.py teacher_off_tel / eval_bag on train_queries
  claim      : V2-S20 "teacher-off bag" PASS; telemetry shows teacher=0 learn=0 freeze=1
               and physical_lanes_active=16 / logical_agents_active=256
  evidence   : telemetry is a static dict (no DUT/XSim); top1/topk come from host
               score_fn on train_queries, not from blind_packets.json execution
  why it matters: a reader can treat flag+lane counts as HS-02 / silicon teacher-off
               proof; contract itself says harness teacher-off ≠ V2 board exam
  fix        : drop fabricated lane/agent fields; label S20 as HARNESS in-bag acquisition
               + packet-shape check only; keep HS-02 for board kit
```

```
[MINOR] V2-C2 gate predicate does not test cleared learned state
  where     : train_v2_harness.py gates["V2-C2_reset_clears_learned"]
  claim      : "V2-C2 reset clears learned; bits MATCH"
  evidence   : predicate is `gen_after_reset >= 2 and forget_a is not None`
               (boolean is never None); empty priors asserted earlier but not gated
  why it matters: weak automated gate could green without proving wipe
  fix        : gate on `priors=={} and edges=={}` immediately after reset_learned
```

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | **Not found** (host is the model; thresholds preregistered) |
| Failing test deleted / tolerance widened mid-run | **Not found** |
| Seed cherry-pick / shrunk bag | **Not found** (fixed 8q / 4 held-out) |
| TRAIN leak into EVAL as BOARD | **N/A silicon** — in-bag top1 is HARNESS acquisition (finding #2) |
| Host gradient / winner as answer path on board | **Not claimed** — HARNESS host scoring only |
| Frozen LM/01R/02M/A0.3 overwrite | **Not found** (SHA MATCH) |
| Control dump content edit | **Not found** (canonical SHA stable) |
| BOARD_PASS / HS-02 self-declare | **Not found** |
| Metric collapse (rank→1) disguised as win | **N/A** (not encoder M_L1 lane) |

---

## allow_loop_done_eng

**true** — protocol HARNESS PASS is file-backed; orchestrator may advance the queue.

Constraints (non-negotiable):

- Status label: prefer **`DONE_HARNESS`**; if `DONE_ENG`, must retain `Evidence_class=HARNESS` and marker `A7NG_TRAIN_V2_HARNESS_PASS`.
- **Not** HS-02 silicon. **Not** §14 SoC. **Not** BOARD_PASS.
- No XSim marker required for this unknown (owned path = harness + tests); do not invent one.
- This auditor does **not** flip `LOOP_STATE.json`.

---

## NOT VERIFIED

- pytest re-execution in this audit session (artifacts + independent Python re-derive used instead).
- Whether `METRICS_PREREGISTERED.json` existed on disk *before* first human-visible run (harness writes it at start of `run_experiment`; `declared_before_run` is self-asserted).
- Board teacher-off / HS-02 / integrate SoC (explicitly out of scope).
- Encoder H5 / ungated DIFF twin (parked; not this gate).
