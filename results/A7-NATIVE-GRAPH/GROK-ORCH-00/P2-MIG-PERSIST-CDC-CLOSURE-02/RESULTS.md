# P2-MIG-PERSIST-CDC-CLOSURE-02 — post-route PROGRAM=NO

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 / Teacher-Off / BOARD_PASS.  
Parent MIG-PERSIST bit `F06C6E84…C482489` **preserved**. COFIT `2E18B144…` preserved.

## Unknown (answered)

Was the MIG-PERSIST-01 CDC increase (candidate_logic 2→3) a persist `core_clk↔clk_pll_i` crossing?

**Yes.** Exact post-route details (parent DCP):

| ID | Start | End |
|----|-------|-----|
| CDC-10 | `u_ab/u_soa/u_br/tr_cnt_reg[2]/C` | `u_persist_grant_sync/meta_reg[1]/D` |
| CDC-1 | `u_persist_axi/c_ok_hold_reg/C` | `u_persist_axi/c7_ready_o_reg/D` |
| CDC-1 | `u_persist_axi/c_ok_hold_reg/C` | `u_persist_axi/ddr_ack_o_reg/D` |

COFIT's two `clk_pll_i→core_clk` Unsafe are `u_wdma_rel_sync` CDC-10 — **not persist**. Kept as FINDING.

## Fix (no false-path)

1. Register `{r_path_idle, soa_running}` on `core_clk` before `sync_bits`.
2. Persist bridge: request toggle + ASYNC_REG 3-flop; capture stable payload on synced edge; ack toggle + capture `ok`/`rdata` in core before pulsing C7/`ddr_ack`. G4 persist SHA unedited.

## Unit / regressions

| Check | Marker |
|-------|--------|
| Dual-clock CDC | `PERSIST_AXI_CDC_XSIM_PASS` req=16 ack=16 phase=3ns rst_skew=ui_first bp=1 |
| AXI 7 cells | `PERSIST_AXI_MIG_XSIM_PASS` CELLS=7 BRESP/RRESP/RLAST |
| Collision | dual=0 |
| AFAST | pred **249** logit0 **1623245** |
| G5 R1 | OUT 549/861/549/237 CELLS=9 |

`CDC_CLOSURE_REGRESSION_PASS`

## Physical (this bag)

```text
persist_crit=0
candidate_logic=2  (wdma_rel_sync only; COFIT-class FINDING)
core_clk→clk_pll_i Unsafe=0
clk_pll_i→core_clk Unknown=0
SLICE used=15405 tot=15850 free=445
WNS=+1.276 TNS=0 WHS=+0.014 THS=0
route_err=0
BRAM36=103 RAMB18=1 DSP=19
```

Post-route Critical persist-named rows: **0**. Remaining CDC-10: CLOCK_GEN `mig_rst_n` + two `u_wdma_rel_sync`.

## Bit (written only after persist_crit=0 and gates PASS)

```text
arty_a7_ng_native_v1_grok_orch_p2_mig_persist_cdc_closure_02.bit
BIT_SHA256=D5B725CF44614E6D90EDF997435E6051BE66723037E9B5DE688E799306D22C22
bytes=3826011
PROGRAM=NO
```

Vs MIG-PERSIST-01: free 417→445. Timing still WNS=+1.276.

## Explicitly not claimed

Teacher-Off, Gate14, BOARD_PASS, silicon BRAM-loss, COM12/JTAG.

## STOP

Codex audit / token. PROGRAM=NO.
