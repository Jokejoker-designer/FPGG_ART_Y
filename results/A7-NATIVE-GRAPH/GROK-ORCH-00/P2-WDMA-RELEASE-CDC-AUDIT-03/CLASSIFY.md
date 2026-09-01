# P2-WDMA-RELEASE-CDC-AUDIT-03 — classify before RTL

**PROGRAM=NO.** Sources: CDC-CLOSURE-02 post-route details + live SoC RTL.

## Exact Critical endpoints (CDC-CLOSURE-02 `report_cdc_details_post.rpt`)

| ID | Sev | Start (ui / `clk_pll_i`) | End (core) | Payload |
|----|-----|--------------------------|------------|---------|
| CDC-10 | Critical | `wdma_arr_outst_reg[3]/C` | `u_wdma_rel_sync/meta_reg[0]/D` | `wdma_arr_quiet_ui = (wdma_arr_outst == 0)` |
| CDC-10 | Critical | `u_wdma/FSM_onehot_st_reg[5]/C` | `u_wdma_rel_sync/meta_reg[1]/D` | `wdma_dma_idle_ui = (wdma_dbg_st == 0)` |
| CDC-10 | Critical (CLOCK_GEN) | `mig_rst_n_reg/C` | MIG `rstdiv0_sync_r` | documented falsepath — not this gate |
| CDC-2 | Warning | XPM `ram_empty_i_reg/C` | `u_wdma_rel_sync/meta_reg[2]/D` | `wdma_cmd_empty_ui = u_wdma_cdc.cmd_empty` |

COFIT-00 same class (source bits `[0]` / `[2]` vs persist-era `[3]` / `[5]`): pre-existing `u_wdma_rel_sync`, not persist.

## RTL packing (live)

```text
async_in = {cmd_empty_ui, dma_idle_ui, arr_quiet_ui}   // WIDTH=3 into sync_bits
dest AND → drop wdma_owner_grant
  !wdma_owner && !dbg_tile_miss && cmd_empty_c && dma_idle_c && arr_quiet_c
```

`sync_bits` is a 2-FF with `ASYNC_REG` only on `meta` (not `sync_out`). Inputs 0 and 1 are **combinational compares**, not FF Q.

## Classification

**ACTUAL_UNSAFE** — not a synchronizer-metadata false-positive, not “only missing ASYNC_REG”.

1. **CDC-10 is real combo-before-sync.** Equality of a 4-bit counter / one-hot FSM can glitch into the first dest flop. A captured glitch synchronizes as a valid 1.
2. **Coherent 3-bit control, independently synchronized.** Dest ANDs the three dest bits to **release mux ownership**. Stale 1s on two bits plus a late 1 on the third produce a `{1,1,1}` that never existed on `ui_clk` → **premature grant drop** while AR still outstanding.
3. CDC-2 on `cmd_empty` is a **Warning** (registered FIFO empty, missing source ASYNC_REG). That bit alone would be “prove + maybe ASYNC_REG”. Combined with (1)+(2) the vector is unsafe.

Do **not** false-path. Do **not** leave as FINDING if this gate is to close candidate_logic.

## Fix (this gate)

Register `{empty, idle, quiet}` on `ui_clk`. AND in the source domain. 3-flop `ASYNC_REG` the AND as dest **level** (grant samples a level so the owner-drop window cannot be missed). Toggle/ack around the same AND for exactly-once idle-window pulse + TB. No 3-bit bus sampled on dest. No false-path.

## Clock-gen

`mig_rst_n` → MIG `rstdiv0_sync_r` remains documented CLOCK_GEN_FALSEPATH. Not candidate_logic.
