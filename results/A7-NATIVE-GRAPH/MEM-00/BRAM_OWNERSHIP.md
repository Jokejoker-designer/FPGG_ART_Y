# MEM-00 — BRAM ownership audit (Native Graph lane)

**Source (primary):** `results/A7-NATIVE-V1/LM06_Q0_BRAM/LM06_BRAM_OWNERSHIP.md`  
**Util:** `build/out/a7lm06_utilization_route.rpt` → **132 / 135** BRAM tiles  
**HS-11:** naive A0.3+01R+02M+LM-06 = **243/135 = 180%** — integration without sharing is illegal.

## Classification of 132 LM-06 tiles

| Owner | Tiles | Lifetime class | Shareable-by-phase? | DDR-backable? | Quant-sensitive? |
|-------|------:|----------------|---------------------|---------------|------------------|
| `u_a` activation | 66 | **transient** scratch | YES (vs graph expand) | partial | no (activations) |
| `u_w` weight staging | 64 | **transient** tile buffer | limited | weights already DDR; buffer may shrink if shape-sized | **YES** |
| `u_snap` snapshot | 2 | **persistent** within run | no | optional | no |

## Integration lever ranking (from measured audit)

1. DDR-back **01R + 02M** → up to **108** tiles (MEM-01/02)  
2. Phase-share LM activation scratch with graph hotset → up to **66**  
3. W2 weight staging (only if `u_w` shape-sized) → up to **48**

**W2 alone does not make V1 fit** (best case still ~144% BRAM).

## PASS criteria for MEM-00

- [x] 132 tiles attributed by hierarchy  
- [x] classes assigned  
- [x] naive 180% called illegal  
- [x] next lever = MEM-01/02 not quant hope  

**Marker:** `A7NG_MEM00_BRAM_AUDIT_PASS`
