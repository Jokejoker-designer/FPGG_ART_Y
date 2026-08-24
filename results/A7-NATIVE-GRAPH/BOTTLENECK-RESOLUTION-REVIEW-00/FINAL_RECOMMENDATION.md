# FINAL_RECOMMENDATION — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Gate:** `NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00`  
**Date:** 2026-08-22  
**LOOP_STATE:** unchanged (`next=STOP`)

---

## CURRENT AUTHORITY (summary)

| Item | State |
|------|-------|
| Goal | `NATIVE_V1_MINI_AI_BOARD_PASS` — **NOT EVIDENCED** |
| Memory chain through `lm06_wm_00` | DONE_ENG PASS_NARROW (XSim bit-exact) |
| `mig_board_r2` | DONE_ENG BOARD_MIG 16/16, WNS +1.060 ns |
| `ddr_wavefront_00` | PASS_NARROW — 16-wide emit, **no** sustained throughput win |
| BRAM naive stack | 243/260/264 **FALSIFIED** |
| HS-22 / semantic HS-02 | **OPEN** |
| Encoder lane | **PARKED** |
| Carried risk | Per-wave Top-K without global reducer |

---

## SUBAGENTS (review-only)

- [Memory roofline](05cedea3-cab8-40cb-8336-852f4093af6f) — `a7-ng-memory-arch`
- [LM working set](d143cb6c-3569-4c25-89fd-aed3d37d7e0f) — `a7-ng-memory-arch`
- [HLB integration](3f5bba31-cfad-4cdd-ad3b-c568b2cdf47b) — `a7-hlb-auditor`
- [Encoder science](0c181efd-9398-48a3-8e2a-b8cae701e75a) — `a7-ng-scientific`

---

## PROPOSAL VERDICTS

### PROPOSAL A — GLOBAL TOPK

**ACCEPT (AMEND)**

Reuse NG-02R 16→8 primitive for `G_(t+1) = TopK(G_t ∪ TopK(W_t))`. Require new integration `law_id`, counterexample streams, and metadata fetch only after `G_final`. WF-GLOBAL-TOPK-00 is **mandatory** before retrieval/HS-02 claims.

### PROPOSAL B — DDR ACCESS-PATTERN / CUE SOA

**ACCEPT (AMEND)**

Valid byte-reduction direction; **not measured** yet (still 16 B/cand). Gate only after global Top-K + **`DESCRIPTOR-CONTRACT-00`** (human-approved). **Minimum stage-1 descriptor is NOT YET FROZEN.** Known lower bound: `node_id` 32 + lawful `node_cue` 64 = **96 bits**. If `learned_prior` becomes per-node lawful field: **104 bits** — resolve in descriptor-contract audit before SOA. `{cue,cue}` replication and broadcast `learned_prior_i` are wiring artifacts, not law proof. Static dataset packing ≠ host winner computation.

### PROPOSAL C — LM06 REUSE-DISTANCE PARETO LADDER

**ACCEPT (AMEND)**

Pareto + stop-at-first-good is sound. Fixed 96/64/48/32 are **ceilings**, not predetermined cuts — **RECOMMEND_MASTERPLAN_AMENDMENT**. MRC traces required before rung claims. Human re-open of `lm06_wm_ladder` still required.

### PROPOSAL D — BRAM PHASE OWNERSHIP

**ACCEPT (AMEND)**

FSM sequence matches doctrine. Add dirty-policy counters, DDR idle wait, measured `phi_switch`. One-writer-per-bank invariant not yet evidenced.

### PROPOSAL E — HS22 SINGLE REAL LM06

**ACCEPT (AMEND)**

Reject TinyGPT/UA additive duplication (260/264 FALSIFIED). One frozen LM-06 core + phase-shared pool. `lm_path=1` ≠ HS-22. Requires MAC/DSP/token path proof.

### PROPOSAL F — ENCODER COLLAPSE DIAGNOSTICS

**ACCEPT (AMEND)**

ENC-GEOM-DIAG-00 on twin reference model with frozen triplet+S3 law. **Preregister transform before E_balance/E_corr:** sign-space `b_ij=sign(h_ij)` for bit balance / binary correlation; continuous `z_ij=standardized(h_ij)` for covariance / effective rank — **do not** label raw int16 covariance as `E_corr`. **REJECT** ungated DIFF. Parallel to graph; no glue; **REFERENCE_MODEL only**.

---

## PRIMARY HYPOTHESIS (§2)

**ACCEPT (AMEND)** — BRAM and DDR are coupled through **phase scheduling and total B_peak**, not a single shared buffer knob. Minimize memory waiting subject to BRAM≤135, exactness, and frozen laws.

---

## MASTERPLAN CONFLICTS

See `MASTERPLAN_CONFLICTS.md`. Key: amend ladder semantics; do not skip WF-GLOBAL-TOPK; SOA logical/physical split allowed with golden tests.

---

## HIGHEST-VALUE NEXT GATE

**`WF-GLOBAL-TOPK-00`**

Closes `carried_risk_r1` — the only active **correctness** defect in the memory/retrieval chain. Unblocks honest SOA survivor fetch and HS-02 ordering.

Parallel (lower urgency): `record_schema_freeze` (doc integrity).

**Human approval:** `HUMAN_APPROVAL_20260822.md` — review authorized as decision basis; three corrections binding.

---

## DO NOT DO NEXT

1. Open `lm06_wm_ladder` / `bram_owner_00` without human re-open  
2. Semantic HS-02 or §14 claim on current SoC  
3. Raise MIG outstanding without `in_flight` telemetry  
4. Treat 8 B compact cue as full TermGen stage-1  
5. Ungated DIFF encoder law  
6. TinyGPT + LM additive BRAM stack  
7. Metadata fetch on per-wave Top-8 winners  
8. Claim 16× throughput from wavefront  
9. Program COM12 / change frozen bits (out of review scope)  
10. Weighted Pareto score without human-approved weights  

---

## PASS-FAIL

**PASS** — Review is evidence-grounded, adversarial where required, artifacts filed under `BOTTLENECK-RESOLUTION-REVIEW-00/`. No RTL, LOOP_STATE, or bitstream changes.

---

## NEXT

**STOP — HUMAN DECIDES**

Recommended human actions:
1. Approve `WF-GLOBAL-TOPK-00` preregistration and dispatch  
2. Approve masterplan ladder documentation amendment (trace-driven rungs)  
3. Re-open `lm06_wm_ladder` only after (1) and MRC scope for `lm06_wm_01`  
4. Keep encoder lane on ENC-GEOM-DIAG-00 (REFERENCE_MODEL) if encoder work is desired  

---

## Artifact index

| File | Purpose |
|------|---------|
| `CURRENT_STATE_RECONCILIATION.md` | Verify A–D claims |
| `FORMULA_TO_SIGNAL_MAP.md` | Counter semantics |
| `MEMORY_ROOFLINE_REVIEW.md` | DDR/roofline/SOA |
| `LM06_WORKING_SET_REVIEW.md` | Ladder/MRC/BRAM fit |
| `GLOBAL_TOPK_REVIEW.md` | WF-GLOBAL-TOPK-00 |
| `HS22_INTEGRATION_REVIEW.md` | Owner FSM, HS-22, HS-02 |
| `ENCODER_SCIENCE_REVIEW.md` | ENC-GEOM-DIAG-00 |
| `PROPOSED_GATE_DAG.md` | Edge validation |
| `MASTERPLAN_CONFLICTS.md` | Q1–Q10 |
| `SUBAGENT_DISAGREEMENTS.md` | Reconciliation |
| `FINAL_RECOMMENDATION.md` | This file |
