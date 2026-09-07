# RESULTS — U8-SOC-ROOTB-WDMA-00

```text
GATE              = U8-SOC-ROOTB-WDMA-00
RESULT            = PASS
FIRST_DIVERGENCE  = NONE (this run)
WIRE              = a7ng_wdma_cdc.m_go_ready
EVIDENCE_CLASS    = XSIM + RTL_FACT
SOC_TOP           = NOT instantiated
MIG               = NOT instantiated
PERSIST_GEN_FAST  = DISCONNECTED (not DUT)
C7_ADDR           = OBSERVE_ONLY (bridge c7_valid_i=0, SoC match)
RTL_EDIT          = YES (m_go_ready; dest dma_go_ready default 1)
SOC_TOP_EDIT      = NO
BIT               = NO
PROGRAM           = NO
```

## DUT (SoC-reachable slice, not full chip)

Persist: `a7ng_learned_prior_store` → `a7ng_persist_axi_bridge` → bag AXI stub
(same objects SoC top wires; `c7_valid_i=0` as `arty_a7_ng_native_v1_ab_soc_top`).

WDMA: `a7ng_wdma_cdc` → `ddr_tile_dma` → always-ready AXI slave.
Dest-like one-cycle `m_go` after `m_go_ready`. No MIG. `weight_tile803k` not xvlog'd.

## Matrix

| Case | Stimulus | Result |
|------|----------|--------|
| A | persist boot, grant blocked then released | PASS |
| B | 3 BRAM updates; ACK ⇔ commit_seq; no AXI write | PASS seq=ack=3 |
| C | 33rd distinct key store-full | PASS NAK, seq stays 32 |
| D | FLUSH with AXI stall | PASS AW=BRESP=wr_ok=65 |
| E | kill + RELOAD through AXI | PASS first-3 hit, 33rd miss |
| G | WDMA delayed grant, dest wait, 128 B | PASS cmd=1 s_go=1 m_done=1 BRESP=1 ready drops on hold |
| H | dest wait; second GO after ready | PASS ovf=0 cmd=2 s_go=2 m_done=2 BRESP=2 |
| I | WDMA mid-txn both-domain rst + one post-rst commit | PASS ACK=1 BRESP=1 hold=0 ovf=0 |

## xsim.log (authoritative tail)

```text
CASE_A_BOOT_STALL PASS boot_done=1 wr_ok=0 rd_ok=1 aw=0 ar=1
CASE_B_UPD_ACK_EQ_COMMIT PASS seq=3 ack=3 pdone=4 axi_aw=0
CASE_C_STORE_FULL done=0 nak=1 seq=32 ack=32
CASE_C_OVERFLOW_NAK PASS
CASE_D_FLUSH_STALL PASS beats=65
CASE_E_FLUSH_RELOAD PASS
CASE_G_WDMA_STALL cmd_wr=1 s_go=1 m_done=1 b_ok=1 ovf=0 dma_st=0 under=1 ready=1
CASE_G_WDMA_STALL PASS ACK=1 BRESP=1
CASE_H_BACKPRESSURE ready=0 hold=1 ovf=0
CASE_H_WDMA_READY_WAIT ovf=0 cmd_wr=2 s_go=2 m_done=2 b_ok=2
CASE_H_WDMA_READY_WAIT PASS ACK=2 BRESP=2 ovf=0
CASE_I_MID_RST dma_st=1 hold=0 cmd_wr=4
CASE_I_AFTER_RST hold=0 ovf=0 dma_st=0 ready=1
CASE_I_POST_RST cmd_wr=1 s_go=1 m_done=1 b_ok=1 ovf=0
CASE_I_MID_TXN_RESET PASS ACK=1 BRESP=1
U8_SOC_ROOTB_WDMA_PASS
```

No `FIRST_DIVERGENCE`. `$finish` 56805 ns. Prior fail retained as
`xsim_054007_fail.backup.log` (`WDMA_SILENT_DROP` cyc=5397).

## What this does not prove

- `arty_a7_ng_native_v1_ab_soc_top` instantiated
- SoC top wired `m_go_ready` → dest `dma_go_ready` (default 1)
- `weight_tile803k` dest FSM in this snapshot
- persist_gen_fast repaired
- C7 as commit identity
- SoC owner-mux + WDMA + persist concurrent
- silicon / Gate14 / BOARD_PASS / OUT=653
