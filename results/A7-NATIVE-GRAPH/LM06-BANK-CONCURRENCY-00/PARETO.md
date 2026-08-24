# PARETO — LM06-BANK-CONCURRENCY-00 (AMENDED)

No weighted total score. Evidence class for bounds: `CURATED_DERIVATION`.

## Frontier sketch (amended)

| Candidate | Est. BRAM Δ | Cycles risk | DDR risk | Dominated? |
|-----------|------------:|-------------|----------|------------|
| **R0 BOARD tensor reachability** | 0 or **−34** if removable | n/a (read-only) | n/a | **P0 information gain** — not a save yet |
| D1 snap BRAM→LUTRAM | **−2** (cross-resource) | low | none | Pareto small; ~1K+ LUT, NEEDS_SYNTH |
| F1 pingpong lifetime | 0..−16 | med | low-med | **Only after R0=A** |
| C tail co-pack | 0 | low | none | dominated unless mapping found |
| A serialize ATT ports | 0 | high | none | dominated |
| B multipump | UNKNOWN | timing HIGH | none | research-only |
| G DDR-back act | large | high | **high** | dominated on ρ_bytes |

## Interpretation (amended)

1. CORE act/weight: **port topology closed** — headroom 0.
2. Snap: **no topology headroom**; LUTRAM is migration, not reclaiming a wasted tile.
3. Do **not** run F1 before proving BOARD tensor is on the LM06 causal cone.
4. Frontier membership ≠ measured BRAM savings.
