# CDC DIFF — MIG-PERSIST-01 vs COFIT-00 (post-route DCP, before RTL patch)

**PROGRAM=NO.** Evidence from `report_cdc -details` on both DCPs.

## Summary table (classify)

| Pair | COFIT Unsafe | PERSIST Unsafe | PERSIST Unknown |
|------|-------------:|---------------:|----------------:|
| c166_raw → clk_pll_i | 1 CLOCK_GEN | 1 CLOCK_GEN | 0 |
| core_clk → clk_pll_i | 0 | **1** | 0 |
| clk_pll_i → core_clk | 2 | 2 | **2** (new) |

candidate_logic 2→3 is the extra **Unsafe** on core_clk→clk_pll_i.

## Exact Critical endpoints — PERSIST DCP

### NEW persist (not in COFIT)

| ID | Sev | Start | End | Class |
|----|-----|-------|-----|-------|
| CDC-10 | Critical | `u_ab/u_soa/u_br/tr_cnt_reg[2]/C` | `u_persist_grant_sync/meta_reg[1]/D` | persist grant: combo `soa_running` before sync |
| CDC-1 | Critical (Unknown col) | `u_persist_axi/c_ok_hold_reg/C` | `u_persist_axi/c7_ready_o_reg/D` | persist bridge: UI bit sampled on core |
| CDC-1 | Critical (Unknown col) | `u_persist_axi/c_ok_hold_reg/C` | `u_persist_axi/ddr_ack_o_reg/D` | persist bridge: UI bit sampled on core |

Also persist Warnings (not the 2→3 count): CDC-2 missing ASYNC_REG on `c_tog`/`c_done_tog`; CDC-15 CE payload `c_slot`/`c_kind`/`c_wdata`/`c_rdata_hold`.

### PRE-EXISTING (COFIT, not persist)

| ID | Sev | Start | End |
|----|-----|-------|-----|
| CDC-10 | Critical | `wdma_arr_outst_reg[3]/C` | `u_wdma_rel_sync/meta_reg[0]/D` |
| CDC-10 | Critical | `u_wdma/FSM_onehot_st_reg[5]/C` | `u_wdma_rel_sync/meta_reg[1]/D` |
| CDC-10 | Critical | `mig_rst_n_reg/C` | MIG `rstdiv0_sync_r` (CLOCK_GEN falsepath) |

COFIT `clk_pll_i→core_clk` Unsafe=2 = the two `u_wdma_rel_sync` CDC-10 rows. **Not persist.** Keep as numeric FINDING.

## Decision

Persist crossing **is** unsafe (grant CDC-10 + bridge CDC-1). Fix: register grant sources on core_clk; request/ack toggle + ASYNC_REG 3-flop + capture stable payload. No false-path.
