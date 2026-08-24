# A7-EAM-02H — Hidden Geometry Audit

**Status:** MEASURED — `Q1P_NOGO`. Not Q2. Not 02A. Not RTL. See `results/A7-EAM-02H/audit.md`.  
**Law:** `eam02h-audit-v1`  
**Depends on:** frozen TinyGPT803k(seed=2), same bags as 02Q geometry.  
**Forbidden:** new weights, retrain, silent-tune Q1 seed, pick pooling/layer on HOLD, glue LM-06, open Q2 because Hamming failed.

## Question

Does the existing `h ∈ Z^{128}` contain **any** PARA/UNREL signal *before* a 64-bit map?

If raw (or cheap-pooled) hidden does not separate, a learned Q2 hash can only fit the 8 pairs. That is not metric learning.

## Grid (frozen before looking)

Representations, all from **one** forward, no weight change:

| Family | Cells |
|--------|--------|
| Last token | `L0_last` … `L3_last` |
| Mean last N tokens | `L{0..3}_mean{4,8,16}` |

Tokenizer unchanged: UTF-8 bytes → token IDs, last `C=128`.  
Mean of `k` tokens uses `min(k, T)`. Integer hidden, float mean for the tape.

## Metrics (pair → scalar)

- **L1** = `∑ |a_i − b_i|` (also mean-abs)
- **L2** = `√∑ (a_i − b_i)²`
- **cosine** = `⟨a,b⟩ / (‖a‖‖b‖)` (higher = closer)
- **sign-agreement** = fraction of dims with the same sign (`0` agrees only with `0`)
- **pearson** = dim-aligned Pearson of the two 128-vectors
- **per-dim** = for each dim, mean `|Δ|` on PARA vs UNREL; count dims with PARA < UNREL

Bags: **PARA**, **UNREL**, **NATIVE** same-k / diff-k (diagnostic).  
**HOLD** is scored after the grid; it must not choose layer or `N`.

## Pre-registered candidate rule (PARA/UNREL only)

A cell is a **Q1P candidate** only if **both**:

1. `mean_cos(PARA) ≥ mean_cos(UNREL) + 0.20` **and** `mean_cos(PARA) ≥ 0.35`  
   **or** `mean_L2(UNREL) ≥ 1.5 × mean_L2(PARA)`
2. At least 6 of 8 PARA pairs have cosine **above** the UNREL cosine median

If several pass, priority (frozen, not argmax after peek):

`L3_mean8, L2_mean8, L1_mean8, L0_mean8,`  
`L3_mean16, L2_mean16, L1_mean16, L0_mean16,`  
`L3_mean4 … L0_mean4,`  
`L3_last … L0_last`

HOLD **confirms** the first candidate: the HOLD paraphrase pair must be closer (higher cosine, lower L2) than **both** HOLD unrelated pairs. Fail confirm → no Q1P.

NATIVE separation without text separation is **task geometry**, not sentence meaning. It does not authorize Q1P for PARA queries.

## If a candidate confirms → Q1P (later, not this file)

```
hidden stream → sum last N → shift/normalize → frozen Q1 ±1 → 64-bit
```

No DSP budget, no new trainable map. Still not 02A.

## If nothing passes

Do **not** open Q2. Write that this 128-D stream, under this tokenizer, has no usable associative signal. Next is representation (how we form `h`), not a learned hash of noise.

**Successor (2026-08-19):** do **not** retune LM-06, Q1, or 01R. Practical lane is **A7-EAM-02M** (multi-cue bind, not paraphrase). Research lane is **A7-EAM-03E** (dedicated episodic encoder). Q2 on this hidden stays closed.

## Deliverables

- this contract
- `tools/a7eam02h_hidden_audit.py`
- `results/A7-EAM-02H/audit.json` + `audit.md`
