## Summary

P0 first-divergence audit: reject dirty DDR as `GEN=0xFFFFFFFF` at P_BOOT.

Do **not** merge as a GATE14_PASS. This is XSim-closed classification + a one-file header check. Silicon unique-bit replay is still open.

## What changed

- `rtl/native_graph/learn/a7ng_learned_prior_store.sv` — `header_ok()`: FLUSH format + `gen<=WRAP_LIMIT`, else P_CLR.
- Evidence bag `results/A7-NATIVE-GRAPH/GROK-ORCH-00/G14-DOWNSTREAM-P0-GEN-BOOT-00/` with pre/post XSim logs.

## What did not change

Oracle 653 / `8382238122802120`. Scorer, Top-K, C9 pack, TinyGPT, bind. No second program. No A0B338E0.

## Proof

Pre-patch TWO_FREE C9 = silicon `2322838281802120`.  
Post-patch ONES/TWO_FREE C9 = oracle `8382238122802120`.  
C9-03 regression PASS.

## Hard stops

```
GATE14_PASS=NO
BOARD_PASS=NO
PROGRAM=NO until unique SHA (C9-07 fileset + this store only)
```
