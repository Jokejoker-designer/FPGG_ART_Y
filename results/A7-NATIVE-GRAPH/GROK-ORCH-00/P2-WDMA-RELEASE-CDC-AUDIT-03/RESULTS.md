# P2-WDMA-RELEASE-CDC-AUDIT-03 — post-route PROGRAM=NO

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 / Teacher-Off / BOARD_PASS.  
Parent CDC-CLOSURE-02 bit `D5B725CF…D22C22` **preserved**. MIG-PERSIST `F06C6E84…` and COFIT `2E18B144…` preserved.

## Classify (before RTL)

The two remaining Critical CDC-10 rows were **ACTUAL_UNSAFE**, not a metadata false-positive and not “only missing ASYNC_REG”.

| ID | Start | End | Payload |
|----|-------|-----|---------|
| CDC-10 | `wdma_arr_outst_reg[3]/C` | `u_wdma_rel_sync/meta_reg[0]/D` | combo `(arr_outst==0)` |
| CDC-10 | `u_wdma/FSM_onehot_st_reg[5]/C` | `u_wdma_rel_sync/meta_reg[1]/D` | combo `(dbg_st==0)` |

Packed `{cmd_empty, dma_idle, arr_quiet}` independently 2-FF’d, then dest-AND dropped `wdma_owner_grant`. Combo glitch + bit-skew can invent `{1,1,1}` while AR still outstanding. CDC-2 on FIFO empty was Warning only.

No false-path.

## Fix

`rtl/board/a7ng_wdma_rel_sync.sv` SHA `56C8AE66…`: register combo on `ui_clk`, AND in UI, dest 3-flop `ASYNC_REG` of the AND (grant samples **level**), request/ack toggle for exactly-once idle-window pulse. Dest does not sample the 3-bit bus.

SoC grant: `!wdma_owner && !dbg_tile_miss && wdma_rel_ok_c`. Handshake ports open on SoC (unit keeps them live).

## Unit / regressions

| Check | Marker |
|-------|--------|
| Dual-clock WDMA rel | `WDMA_REL_CDC_XSIM_PASS` pulse=32 and_rise=32 grant_fall=19 idle_win=16 phase=3ns rst_skew=ui_first |
| Dual-clock persist CDC | `PERSIST_AXI_CDC_XSIM_PASS` req=16 ack=16 |
| AXI 7 cells | `PERSIST_AXI_MIG_XSIM_PASS` CELLS=7 BRESP/RRESP/RLAST |
| Collision | dual=0 |
| AFAST | pred **249** logit0 **1623245** |
| G5 R1 | `TEACHER_OFF_SOC_XSIM_PASS` fails=0 CELLS=9 LM_KNOWN |

`WDMA_REL_CDC_REGRESSION_PASS`

## Physical (this bag)

```text
candidate_logic=0
persist_crit=0
clk_pll_i→core_clk Unsafe=0 (65 Safe)
core_clk→clk_pll_i Unsafe=0 (107 Safe)
remaining Critical=1 CLOCK_GEN c166_raw→clk_pll_i (documented)
wdma_rel CDC-3 Info: and_q_reg → and_s0_reg ASYNC_REG
SLICE used=15423 tot=15850 free=427
WNS=+1.276 TNS=0 WHS=+0.020 THS=0
route_err=0
BRAM36=103 RAMB18=1 DSP=19
```

## Bit (written only after candidate_logic=0 and gates PASS)

```text
arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit
BIT_SHA256=6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
bytes=3826011
PROGRAM=NO
```

Parent D5B still `D5B725CF…D22C22` bytes=3826011. Not overwritten.

## Explicitly not claimed

Teacher-Off, Gate14, BOARD_PASS, silicon BRAM-loss, JTAG program. COM12 may be enumerated on the host; this gate still **PROGRAM=NO**.

## STOP

Codex audit / token. PROGRAM=NO.
