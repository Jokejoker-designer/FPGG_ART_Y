# ENCODER_SCIENCE_REVIEW — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Reviewer role:** a7-encoder-science-reviewer (via `a7-ng-scientific`)  
**Lane status:** `LOOP_STATE.encoder_lane` = **PARKED**

---

## 1. PROPOSAL F — collapse diagnostics (proposal §19–20)

**Verdict: AMEND**

| Element | Assessment |
|---------|------------|
| Diagnostics before new training law | **ACCEPT** |
| No RTL / no graph glue | **ACCEPT** |
| VICReg / Barlow / HashNet as theory only | **ACCEPT** |
| `E_balance`, `E_corr` on `{-1,+1}^K` | **AMEND** — A0.3 `h_final` is **32× int16**, not binary codes |
| Baseline law unspecified | **AMEND** — preregister **triplet hinge + S3 >>3** on twin |
| Ungated DIFF as next step | **REJECT** — E1 falsified 11/11 @ 100k |

---

## 2. ENC-GEOM-DIAG-00 — one unknown

```text
OBSERVATION: Standing candidate (triplet + S3 >>3 @ 100k) still fails worst-seed
             M_L1 / M_cos per E8; geometry metrics never tested as joint predictors.

UNKNOWN:     Under frozen standing law only, do FAIL seeds show higher E_balance,
             E_corr, lower effective_rank, lower margin_success(m) than PASS seeds
             at matched checkpoints?

H_CANDIDATE: Collapse preceded by measurable geometry defects predicting margin inversion.
H_RIVAL:     Failures are horizon-transient / seed-noise only.

FALSIFIER:   No checkpoint separates M_L1 sign at 100k (e.g. AUROC ≤ 0.55).

UNIT:        One (seed × checkpoint) on held-out eval — NOT clock cycle.
CONTROL:     Same splits/seeds as E1/E7/E8; no law change.
EVIDENCE_CLASS: REFERENCE_MODEL only.
```

---

## 3. Measurable today (frozen/twin law)

| Metric | Status | Source |
|--------|--------|--------|
| `effective_rank`, `saturation_rate` | **YES** | `collapse_report()` |
| `d_pos`, `d_neg`, `M_L1`, `M_cos` | **YES** | `eam03e_bench.py`, E1/E7/E8 archives |
| `unique_d1`, AUC checkpoints | **YES** | stability JSON |
| `margin_success(m)` | **NEEDS_INSTRUMENTATION** | derivable from triplet pools |
| `E_balance`, `E_corr` | **NEEDS_INSTRUMENTATION** | preregister transform — see below |

### Preregistered transforms (human-approved 2026-08-22)

Do **not** compute covariance on raw `int16[32]` and label it `E_corr`.

| Space | Transform | Metrics |
|-------|-----------|---------|
| **Sign-space** | `b_ij = sign(h_ij)` | `E_balance`, binary bit correlation |
| **Continuous geometry** | `z_ij = standardized(h_ij)` per dimension | covariance, correlation, effective rank |

---

## 4. Independence from graph evidence

**Q8 answer: YES** — with firewalls:

1. Archive under `results/A7-EAM-03E/ENC-GEOM-DIAG-00/` only  
2. Evidence class **REFERENCE_MODEL** until new law + new bit  
3. No frozen A0.3 / 01R / 02M / LM-06 bit changes  
4. Parallel DAG edge to graph memory work — **VALID**  

**Contamination risk:** Renaming encoder diagnostic PASS as graph/HS-02 progress.

---

## 5. Ungated DIFF — REJECT

**FACT (E1):** Sanity proves gate removal works; outcome 11/11 total collapse @ 100k. Short-horizon peaks are transient (HS-18 violation if promoted).

Stale `MUST_READ_UNBLOCK_H5` "next = ungated DIFF" is **superseded** by E1 for remedy selection. H5 diagnosis (71% DIFF suppression) remains valid **mechanism** evidence.

---

## 6. External sources (proposal §27F)

| Source | Classification | Native role |
|--------|----------------|-------------|
| VICReg | EXTERNAL_THEORY | Inspire E_balance / covariance diagnostics |
| Barlow Twins | EXTERNAL_THEORY | Redundancy diagnostic inspiration |
| Supervised hashing | EXTERNAL_THEORY | Bit-balance hypothesis only |
| HashNet sign continuation | **FUTURE_RESEARCH_ONLY** | Invasive; no A0.3 port without new law |
| Jing dimensional collapse | EXTERNAL_THEORY | Rank/covariance measurement support |

**Do not port** full objectives into A0.3.

---

## 7. Compatibility with encoder authority

**ACCEPT** diagnostic gate if:
- No training law change in ENC-GEOM-DIAG-00  
- Encoder stays PARKED relative to graph LOOP_STATE  
- Human approves any follow-on hypothesis (balance OR decorrelation — **one at a time**)

**REJECT** combining balance + decorrelation + new triplet law in one gate.
