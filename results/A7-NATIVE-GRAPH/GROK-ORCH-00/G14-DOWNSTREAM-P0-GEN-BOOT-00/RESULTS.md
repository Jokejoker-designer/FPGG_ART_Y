# G14-DOWNSTREAM-P0-GEN-BOOT-00 RESULTS

**PROGRAM=NO. Unique silicon bit not built this bag.**  
Does **not** declare GATE14_PASS, BOARD_PASS, EXISTENCE_PASS, or NATIVE_V1_MINI_AI_BOARD_PASS.

Oracle HOLD_A 653 / `8382238122802120` was **not** retargeted.

## Return

```text
GATE=G14-DOWNSTREAM-P0-GEN-BOOT-00
CLASS=STATE_DIVERGENCE
FIRST CONFIRMED DOWNSTREAM FAILURE=P0 P_BOOT header accept
STAGE=S0 generation identity
XSIM_PREPATCH=PBOOT_DIRTY_DDR reproduced GEN=FFFFFFFF; TWO_FREE C9=2322838281802120
XSIM_POSTPATCH=ONES/TWO_FREE C9=8382238122802120 GEN=2 after TRESET
C9_03_REGRESSION=C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0
STORE_SHA256=48B84056F2F15738346E1E6E5BED0989883523075E097E9AFC9AF6BA0B50FBB8
UNIQUE_BIT=not_created
PROGRAM=NO
GATE14_PASS=NO
BOARD_PASS=NO
NATIVE_V1_MINI_AI_BOARD_PASS=NO
```

## P0 GEN answers (RTL + UART + XSim)

| Q | Answer | Class |
|---|--------|-------|
| A legal `0xFFFFFFFF`? | **NO.** Restore requires `1..WRAP_LIMIT(6)`. | FACT |
| B reset/uninit sentinel? | Reset `live_gen<=32'd1`. FF is **not** GSR/reset fill. | FACT |
| C UART-only? | **NO.** `c8_gen_o=live_gen`; vis_w uses `live_gen[7:0]`; wrap uses `live_gen>=6`. | FACT |
| D architectural? | **YES.** 32-bit FF `live_gen`. | FACT |
| E storage | FF `live_gen`; DDR slot0 header `{31'd0,gen,1'b1}`; BRAM stamp=`gen[7:0]`. | FACT |
| F clock | `core_clk` of `a7ng_learned_prior_store`. | FACT |
| G commit | P_BOOT header read (also TRESET +1, rst_n→1). | FACT |
| H query visible | `boot_done` + `vis_w`; C8 samples continuously. | FACT |

Silicon C8 `gen=4294967295` at **boot**, before any fact (`exam_log.json` tag `boot`). Same value after TRESET.

## Pre-patch XSim (EVIDENCE)

`pboot_store_xsim_prepatch.log` / `pboot_graph_xsim_prepatch.log`

| Case | S0 GEN | TRESET GEN | ack | commit_seq | A0-3 hit | HOLD_A C9 |
|------|--------|------------|-----|------------|----------|-----------|
| ZERO (XSim DDR=0) | 1 | 2 | 20 | 20 | 1111 | `8382238122802120` oracle |
| ONES (DDR all-1) | FFFFFFFF | FFFFFFFF | 20 | **0** | 0000 | `2322832182208180` = C3 |
| TWO_FREE (30 vis_w + 2 empty) | FFFFFFFF | FFFFFFFF | 20 | **2** | 1100 | **`2322838281802120` silicon** |
| LEGAL header gen=3 | 3 | n/a | 20 | 20 | 1111 | (store only) |

TWO_FREE C9 **equals** Gate14 silicon HOLD_A pack on bit `3A7EF204`.

## Causal chain (no handwave)

```text
dirty DDR header bit0=1 and bits[32:1]=FFFFFFFF
→ P_BOOT treated it as a live generation (old law: bit0 && gen!=0)
→ live_gen=FFFFFFFF, P_RELOAD of payload
→ vis_w requires stamp==live_gen[7:0]==0xFF
→ TRESET sees wrap (FF>=6), P_INVAL zeros DDR but does NOT reset live_gen or BRAM
→ free list = slots that are not vis_w
→ 20 UART C5/C6/C7 acks still fire (ack_count++)
→ architectural writes only if have_free (commit_seq)
→ TWO_FREE: seq=2, A0+A1 prior only
→ HOLD_A C9=2322838281802120 ≠ oracle 8382238122802120
→ OUT 748 ≠ 653
```

P1 theorem **failed** as a consequence: 20 semantic facts ↛ 20 unique architectural commits.

## Patch (first cause only)

`rtl/native_graph/learn/a7ng_learned_prior_store.sv`

P_BOOT now requires the FLUSH header invariant:

```text
bit0=1 && gen!=0 && bits[63:33]==0 && gen<=WRAP_LIMIT
```

Else `live_gen<=1` and **P_CLR** (zeros BRAM). Illegal all-ones cannot become live_gen.

Not patched (latent, not first): `P_INVAL` still leaves `live_gen`/BRAM; `a7ng_persist_gen_fast.sv` has the old header test but is not the C9 graph store.

## Post-patch XSim (EVIDENCE)

ONES and TWO_FREE: S0 GEN=1, TRESET GEN=2, seq=20, hits=1111, HOLD_A C9=`8382238122802120`.

C9-03 regression: `C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0` packs unchanged.

## Silicon

Frozen fail bit `3A7EF204` remains historical. New unique SHA **not** built: worktree has unrelated dirty cue/scorer/MIG/top files; a mixed bit would not be a one-unknown experiment.

Next unique bit = C9-07 fileset + this store patch only. Arm UART, program once, post-DONE only.
