# A7-EAM-00G — generalization predev (not a close)

**Status:** DEVELOPMENT (sweep taken). Not a close. Silicon `arty_a7_eam00g.bit` SHA `AC548AF7…`, WNS +0.437. Twin vs FPGA `best_d` disagree = 0. See `results/A7-EAM-00/sweep_00g.md`.  
**Question:** query A′ ≈ A — does the Hamming EAM recall A, and can it reject unrelated keys?  
**If reject is poor, do not scale the same metric to 256 MB DDR.**

## Sweep

HIT_MAX ∈ {0,1,2,4,8}

Corruption of a stored key A:

- 0 / 1 / 2 / 4 / 8 bit flips
- modes: `any` (all 64 bits), `tag` (bits [63:8], same set), `set` (bits [7:0], wrong set)
- `unrelated` random key not in the store

## Metrics (FPGA + host slice)

| Name | Definition |
|------|------------|
| true-positive | `best_d ≤ T` **and** winner token = token(A) |
| false-positive | unrelated query with `best_d ≤ T` |
| wrong-hit | `best_d ≤ T` and winner token ≠ token(A) |
| best / second Hamming | native scan of the **set** (16 ways) |
| margin | `second_d − best_d` (64 if no second) |
| collision rate | share of probes with `second_d ≤ T` (ambiguous accept) |
| set occupancy | colliding sets (`occ ≥ 2`) after MAP |

Host does **not** send way / BRAM addr / precomputed match.  
HIT_MAX via CMD `0x07`. RESULT byte 5 is `second_d` (00G; 00B used cycles).

## Evidence

`results/A7-EAM-00/sweep_00g.json` + `sweep_00g.md`. Development only.
