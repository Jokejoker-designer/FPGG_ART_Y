## Summary

Gate14 first **confirmed** XSim-vs-silicon divergence after CORE_DONE is **P0 P_BOOT generation identity**, not scorer / Top-K / C9 pack / TinyGPT.

**Do not retarget the oracle. Do not auto-reprogram. GATE14_PASS / BOARD_PASS / EXISTENCE_PASS are not claimed.**

Parent silicon fail: https://github.com/Jokejoker-designer/FPGG_ART_Y/issues/1  
Reset/START closed on `7ECCA0E2`: https://github.com/Jokejoker-designer/FPGG_ART_Y/issues/3

## Frozen oracle (immutable)

HOLD_A C9 `8382238122802120` OUT **653**.

Silicon bit `3A7EF204` HOLD_A C9 `2322838281802120` OUT **748**. C8 GEN `0xFFFFFFFF` at **boot**.

## Finding

Old P_BOOT accepted any DDR word with `bit0 && gen!=0`. Dirty/all-ones DRAM becomes `live_gen=0xFFFFFFFF`. `vis_w` then requires stamp `0xFF`. C7 `ack_count` still advances. Architectural `commit_seq` does not.

XSim TWO_FREE (30 vis_w + 2 free) **reproduces silicon HOLD_A pack** `2322838281802120` with `commit_seq=2` (A0+A1 only).

## Patch (XSim closed)

`rtl/native_graph/learn/a7ng_learned_prior_store.sv`

Header must match FLUSH `{31'd0, gen, 1'b1}` with `gen<=WRAP_LIMIT(6)`, else `P_CLR`.

Post-patch: dirty DDR boots GEN=1, TRESET GEN=2, 20 commits, HOLD_A C9 = oracle.

C9-03 regression: `C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0`.

## Not done

- Unique silicon bit **not** built (worktree has unrelated dirty lanes).
- PROGRAM=NO until a unique SHA of C9-07 fileset **plus this store patch only**.

```
GATE14_PASS=NO
BOARD_PASS=NO
NATIVE_V1_MINI_AI_BOARD_PASS=NO
```
