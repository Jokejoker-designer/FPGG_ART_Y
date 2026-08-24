# SUBAGENT_DISAGREEMENTS — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

Four read-only reviewers dispatched (mapped to available Cursor subagent types):

| Requested role | Actual subagent | Agent ID |
|----------------|-----------------|----------|
| a7-memory-roofline-reviewer | `a7-ng-memory-arch` | 05cedea3 |
| a7-lm-working-set-reviewer | `a7-ng-memory-arch` | d143cb6c |
| a7-integration-hlb-reviewer | `a7-hlb-auditor` | 3f5bba31 |
| a7-encoder-science-reviewer | `a7-ng-scientific` | 0c181efd |

---

## Disagreement 1 — Primary coupled optimization hypothesis

| Reviewer | Position |
|----------|----------|
| Memory (roofline) | **AMEND** — two orthogonal domains (graph delivery vs LM tiles); coupling at phase schedule only |
| LM working-set | **AMEND** — agrees coupling exists but ladder and SOA are separable experiments |
| HLB | Implicit accept of phase coupling via BRAM-OWNER-00 |

**Reconciliation:** **AMEND accepted.** Proposal §2 core insight (BRAM cuts increase DDR traffic) is **ACCEPT**; treating delivery ping-pong and LM tiles as one optimization variable is **REJECT**.

---

## Disagreement 2 — record_schema_freeze → WF-GLOBAL-TOPK hard edge

| Reviewer | Position |
|----------|----------|
| Proposal DAG | schema freeze before Top-K |
| HLB | **UNNECESSARY** hard dependency — Top-K is logic |

**Reconciliation:** **HLB wins.** Schema freeze is **parallel doc hygiene**; WF-GLOBAL-TOPK has no schema blocker. SOA **does** need schema freeze.

---

## Disagreement 3 — DDR-CUE-SOA vs LM ladder ordering

| Reviewer | Position |
|----------|----------|
| Proposal DAG | SOA before ladder |
| Memory | SOA after global Top-K; ladder parallel after human re-open |
| Doctrine | Delivery measured — ladder is LM-06 tile problem |

**Reconciliation:** **AMEND DAG.** `DDR-CUE-SOA-00` ∥ `lm06_wm_ladder` after `WF-GLOBAL-TOPK-00`. Neither blocks the other once global Top-K exists.

---

## Disagreement 4 — Fixed 96/64/48/32 ladder

| Reviewer | Position |
|----------|----------|
| Proposal §13 | Near-boundary rungs (128, 124, …) may be more informative |
| LM reviewer | **RECOMMEND_MASTERPLAN_AMENDMENT** — keep labels as ceilings |
| Doctrine | Fixed rungs in LOOP_STATE |

**Reconciliation:** **Amend masterplan text only** — retain queue labels; add trace-driven NLIVE and optional intermediate measurement rungs. **No LOOP_STATE edit** in this review.

---

## Disagreement 5 — Cut order u_w vs u_a

| Reviewer | Position |
|----------|----------|
| Proposal §15 | u_a hypothesis (large transient) |
| LM reviewer | **u_w first** — evidence from `live_pair_events`, MEM-00 ranking |

**Reconciliation:** **u_w first for within-LM ladder cuts** until MRC traces exist. u_a phase-share is **bram_owner_00** lever, not first ladder shave. Proposal hypothesis **not authoritative**.

---

## Disagreement 6 — eta_beat formula

| Reviewer | Position |
|----------|----------|
| Proposal §1 | eta_beat = 64/(64+79) ≈ 0.4476 |
| Memory | Valid as derived duty cycle; **AMEND** — not universal DDR efficiency |

**Reconciliation:** **AMEND.** Accept formula with explicit counter definitions in `FORMULA_TO_SIGNAL_MAP.md`.

---

## Disagreement 7 — Encoder E_balance on binary cues

| Reviewer | Position |
|----------|----------|
| Proposal §19 | Binary cue h_i ∈ {-1,+1}^K |
| Encoder science | **AMEND** — int16 h_final; needs mapping before E_balance/E_corr |

**Reconciliation:** **AMEND PROPOSAL F.** Diagnostics gate proceeds with defined binarization or z-score spec.

---

## No unresolved blocking disagreements

Parent reconciliation: all proposals rated **ACCEPT (AMEND)** or **AMEND** except:
- Ungated DIFF: **REJECT** (unanimous)
- 8 B as full stage-1 semantic descriptor: **REJECT** (memory + HLB)
- Skip WF-GLOBAL-TOPK: **REJECT** (HLB + global topk review)
