# GO-GRANT-QUIESCE-00 — RESULTS

**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**PROGRAM:** NO. **JTAG:** NO. **QSTAR on SoC:** NO.

## Prints (authoritative `xsim.log`)

```text
GRANT_HOLD_IN_AR=1
R_BEATS T=8155000 accepted=7 dma_st=0 arr_outst=0 grant=1
UI_QUIET T=8155000 saw=1 dma_st=0 cmd_empty=1 arr_outst=0 grant=1 idle_c=0 empty_c=1 quiet_c=1
GRANT_AFTER_IDLE T=8440000 grant=0 i=4 idle_c=1 empty_c=1 quiet_c=1
OWNED_AR=1
GRANT_HOLD_IN_AR=1
GRANT_DROP_AFTER_IDLE=1
HOLD_ST=4
CLASS=QUIESCE_HOLD
GO_GRANT_QUIESCE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
```

`$finish` at 8440 ns. `INFO: [Common 17-206] Exiting xsim at Sun Aug 30 08:09:29 2026`.

## Class

| Field | Value |
|-------|-------|
| CLASS | **QUIESCE_HOLD** |
| GRANT_HOLD_IN_AR | 1 (grant stayed 1 while DMA in AR after tile dest drop) |
| GRANT_DROP_AFTER_IDLE | 1 (grant fell only after cmd_empty && DMA IDLE && AR/R==0) |
| HOLD_ST | 4 (AR) |
| TOP_ELAB | slice_not_soc |
| UNIT_PASS | YES |
| EXISTENCE / pred=664 / BOARD_PASS | **not claimed** |

## Not proven

Full SoC composition (pending+issue+pop+ready+quiesce+two-pass) on one bitstream. UART `NATIVE_V1_EXIST_ROW,pred=664`.
