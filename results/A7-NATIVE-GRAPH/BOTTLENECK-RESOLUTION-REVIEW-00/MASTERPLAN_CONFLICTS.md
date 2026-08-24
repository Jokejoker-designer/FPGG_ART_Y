# MASTERPLAN_CONFLICTS — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

Answers to proposal §31 masterplan conflict questions.

---

## Q1. Does dynamic BRAM target conflict with fixed 96/64/48/32 ladder?

**YES — as sole execution plan.** WM-00 proved port-demand ≤2 does not justify predetermined cuts. Jumping 132→96 may over-cut and inflate DDR traffic without MRC evidence.

**NO — as ceiling labels.** Keeping 96/64/48/32 as **reporting rungs** remains compatible if amended with trace-driven NLIVE per owner.

---

## Q2. Fixed ladder remain unchanged or amend before human re-open?

**RECOMMEND_MASTERPLAN_AMENDMENT** (documentation only — **do not edit LOOP_STATE** in this review).

Amend:
- `AUTHORITY_MEMORY_DOCTRINE.md` ladder section  
- `08_MEMORY_ARCHITECTITECTURE.md` if it states predetermined cuts  
- Add optional near-boundary probes (128, 124, 120, 112) as **measurement rungs**, not replacement queue ids  

Retain queue id `lm06_wm_ladder` and human re-open requirement.

---

## Q3. Is WF-GLOBAL-TOPK-00 required?

**YES.** NG-02R closes 16→8 **primitive** only. Integrated wavefront has per-batch selection without `G_t`. `carried_risk_r1` accurate.

---

## Q4. Can NodeRecordV1 remain logically frozen while physical DDR layout splits into planes?

**YES (AMEND).** Logical schema frozen (`mem_schema_v1`); physical SOA layout is **access-pattern projection** with golden round-trip tests. Must not change field semantics, score law, or host-visible layout without new `law_id`.

**Q5 follow-on:** DDR-CUE-SOA-00 must not alter retrieval law if descriptor bits and unpack path are lossless and deterministic.

---

## Q5. Would DDR-CUE-SOA-00 alter retrieval law in hidden way?

**RISK: YES if careless.** Risks:
- `{cue,cue}` replication masking 32b effective entropy  
- Prune gate at 8 B ≠ TermGen law  
- Survivor metadata order before global Top-K  

**Mitigation:** WF-GLOBAL-TOPK first; preregister law_id for any stage-1 descriptor narrower than 16 B; oracle-bound false-positive rate.

---

## Q6. Can phase sharing make B_always + max(B_graph, B_lm) realistic?

**PARTIALLY.** Co-fit proxy 132 tiles WNS+0.586 supports **hypothesis** for phase-exclusive pool.

**NOT YET PROVEN** because:
- 01R 56 + 02M 52 not integrated on-chip (DDR-back required)  
- `B_always` incomplete (FIFOs, MIG, encoder concurrency)  
- `bram_owner_00` not evidenced  
- Lifetimes may overlap if encoder concurrent  

Naive sum 243+ remains **FALSIFIED**.

---

## Q7. HS-22 — real frozen LM06 once or duplicate TinyGPT?

**Must be single real LM-06 core.** Measured 260/264 additive stacks **FALSIFIED**. Co-fit proxy is capacity experiment, not HS-22 answer path. Current `lm_path=1` + `pe_alive=0` is visibility only.

---

## Q8. Encoder diagnostic independent?

**YES** with firewalls (separate archive, REFERENCE_MODEL, PARKED lane). Parallel to graph memory work.

---

## Q9. Highest expected-value next gate?

**WF-GLOBAL-TOPK-00** — closes active correctness hole (`carried_risk_r1`) that blocks honest retrieval, SOA survivor fetch, and HS-02 chain.

Runner-up (parallel doc): `record_schema_freeze` — does not unblock retrieval correctness alone.

---

## Q10. Which proposal should NOT be done?

| Do NOT | Reason |
|--------|--------|
| Open `lm06_wm_ladder` without human re-open | LOOP_STATE BLOCKED |
| Semantic HS-02 on current SoC | TinyGPT absent; stub only |
| Increase MIG outstanding without `in_flight` export | Plateau at out=8 |
| 8 B cues as full stage-1 semantic descriptor | TermGen needs 64b node_cue |
| Ungated DIFF encoder law | E1 falsified |
| TinyGPT + LM additive integration | 260/264 FALSIFIED |
| Metadata fetch on per-wave winners | Violates global Top-K |
| Weighted Pareto score without human weights | Proposal §14 |
| Claim wavefront 16× throughput | 0.441 vs 0.444 |
| Port VICReg/Barlow/HashNet into A0.3 | EXTERNAL_THEORY only |

---

## Masterplan vs LOOP_STATE

Where Masterplan roadmap ordering disagrees with `LOOP_STATE`, **LOOP_STATE wins** (`00_CURRENT_AUTHORITY.md` §2 #6). This review does not change `LOOP_STATE.next=STOP`.
