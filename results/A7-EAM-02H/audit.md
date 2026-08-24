# A7-EAM-02H hidden audit

**Decision:** `Q1P_NOGO` — no cell separates PARA/UNREL under the frozen rule. Do not learn a 64-bit hash of this hidden. Q2 stays closed. HOLD unused for selection.

Weights: `TinyGPT803k(seed=2)` unchanged. Tokenizer: UTF-8 bytes.

## What the grid actually says

Last-token (what 02Q Hamming tapped) is **not** sentence meaning:

- `L3_last` cosine PARA **0.286** vs UNREL **0.327** (PARA worse)
- sign-agree ~0.55–0.63 both bags; per-dim tighter on PARA: 60/128 (coin flip)

Pooling **raises cosine for everyone** (collapse toward a shared mean), it does **not** open a PARA/UNREL gap:

- Best Δcos is `L2_mean4` **+0.099** (0.610 vs 0.511), rank 7/8, L2 ratio 1.14
- Frozen bar was Δcos ≥ 0.20 **or** L2 ratio ≥ 1.5, **and** rank ≥ 6. Ratio 1.14 fails; 0.099 < 0.20 fails
- `L3_mean8` (the Q1P default we would have tried first): 0.702 vs 0.690 — essentially the same

So the last-byte hypothesis stands: last-token is local/position. Mean-pool makes vectors generic, not paraphrastic.

## Native last-token corpus (not PARA)

`L0_last` same-k vs diff-k cosine **0.316 vs 0.147** (Δ **+0.169**). That is **last-token identity** (`k∈1..8` vs other k), which is exactly the toy retrieval label, not Vietnamese paraphrase. Pooling wipes it (mean8 Δ ≈ 0). This does **not** authorize Q1P for PARA.

## Cosine / L2 grid

| cell | PARA cos | UNREL cos | Δcos | PARA L2 | UNREL L2 | L2 ratio | rank | cand |
|------|----------|-----------|------|---------|----------|----------|------|------|
| `L3_mean8` | 0.702 | 0.690 | +0.013 | 137570.4 | 139330.4 | 1.01 | 5/8 | False |
| `L2_mean8` | 0.729 | 0.666 | +0.063 | 128061.8 | 143803.0 | 1.12 | 7/8 | False |
| `L1_mean8` | 0.653 | 0.618 | +0.035 | 130242.7 | 138283.9 | 1.06 | 5/8 | False |
| `L0_mean8` | 0.553 | 0.619 | -0.066 | 136973.6 | 126759.6 | 0.93 | 1/8 | False |
| `L3_mean16` | 0.765 | 0.744 | +0.021 | 116721.2 | 120219.7 | 1.03 | 6/8 | False |
| `L2_mean16` | 0.785 | 0.731 | +0.054 | 110193.7 | 122114.6 | 1.11 | 8/8 | False |
| `L1_mean16` | 0.745 | 0.722 | +0.023 | 105701.9 | 111123.4 | 1.05 | 5/8 | False |
| `L0_mean16` | 0.713 | 0.706 | +0.006 | 101793.4 | 104017.1 | 1.02 | 4/8 | False |
| `L3_mean4` | 0.604 | 0.557 | +0.047 | 171440.8 | 180695.0 | 1.05 | 6/8 | False |
| `L2_mean4` | 0.610 | 0.511 | +0.099 | 167743.8 | 191534.0 | 1.14 | 7/8 | False |
| `L1_mean4` | 0.524 | 0.510 | +0.014 | 168688.6 | 173514.5 | 1.03 | 4/8 | False |
| `L0_mean4` | 0.430 | 0.483 | -0.052 | 178154.9 | 169938.6 | 0.95 | 0/8 | False |
| `L3_last` | 0.286 | 0.327 | -0.040 | 322545.3 | 313670.3 | 0.97 | 3/8 | False |
| `L2_last` | 0.311 | 0.242 | +0.069 | 321215.7 | 339974.2 | 1.06 | 5/8 | False |
| `L1_last` | 0.224 | 0.227 | -0.002 | 333170.8 | 332578.9 | 1.00 | 3/8 | False |
| `L0_last` | 0.174 | 0.175 | -0.000 | 344453.8 | 344039.3 | 1.00 | 4/8 | False |

## Native last-token corpus (diagnostic, not PARA)

| cell | same-k cos | diff-k cos | Δ |
|------|------------|------------|---|
| `L3_mean8` | 0.421 | 0.442 | -0.021 |
| `L2_mean8` | 0.415 | 0.411 | +0.003 |
| `L1_mean8` | 0.368 | 0.354 | +0.014 |
| `L0_mean8` | 0.354 | 0.313 | +0.041 |
| `L3_mean16` | 0.421 | 0.442 | -0.021 |
| `L2_mean16` | 0.415 | 0.411 | +0.003 |
| `L1_mean16` | 0.368 | 0.354 | +0.014 |
| `L0_mean16` | 0.354 | 0.313 | +0.041 |
| `L3_mean4` | 0.421 | 0.442 | -0.021 |
| `L2_mean4` | 0.415 | 0.411 | +0.003 |
| `L1_mean4` | 0.368 | 0.354 | +0.014 |
| `L0_mean4` | 0.354 | 0.313 | +0.041 |
| `L3_last` | 0.311 | 0.287 | +0.024 |
| `L2_last` | 0.325 | 0.289 | +0.036 |
| `L1_last` | 0.298 | 0.205 | +0.093 |
| `L0_last` | 0.316 | 0.147 | +0.169 |

HOLD paraphrase must beat both HOLD unrelated if a candidate exists.
