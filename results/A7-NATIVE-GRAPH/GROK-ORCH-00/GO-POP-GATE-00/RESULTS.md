# GO-POP-GATE-00 — RESULTS

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e` + issue-gate CDC + one-wire pop-gate  
**PROGRAM:** NO. **JTAG:** NO. **BOARD_PASS:** not claimed.  
**EXISTENCE:** not claimed. **pred=664:** not claimed.

## CLASS

**POP_GATED**

## Required prints (`xsim.log`)

```text
DROP_S_GO=0
GRANT_S_GO=1
CLASS=POP_GATED
GO_POP_GATE_00_UNIT_PASS
```

## SHA256 `rtl/board/a7ng_wdma_cdc.sv`

| When | SHA256 |
|------|--------|
| BEFORE (CONTROL, post ISSUE-GATE) | `A036F21644EF29E4DA9A9702D01CE26E7AB6994EEFF634A0110F56352DD56E3F` |
| AFTER (one wire) | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |

CONTROL law: `cmd_rd_en = … && (!s_busy || ghost_busy_rel)`  
AFTER law: `cmd_rd_en = … && (!s_busy || ghost_busy_rel) && s_owner`

`cmd_wr_en` not edited this gate. No tile / top / DMA / QSTAR / frozen LM-06/01R/02M.

## XSim transcript tail

```text
GO-POP-GATE-00 START m_period=80ns s_period=10ns
RESET_RELEASED T=1960000
RECOVERY T=5955000 m_owner=1 s_owner=1 cmd_empty=1 cmd_wr_en=0 cmd_rd_en=0
PULSE_OWNED_ENQ T=6040000 m_owner=1 m_go=1 cmd_wr_en=1 cmd_full=0
ENQ_WAIT T=6200000 cmd_empty=0 saw_empty=1 s_owner=1 s_go=0 cmd_rd_en=0 s_busy=1
DROP_M_OWNER T=6200000 m_owner=0
S_OWNER_LOW T=6235000 s_owner=0 cmd_empty=0 cmd_rd_en=0 s_go=0
POP_LEGAL_STUB T=6235000 s_busy=0 s_dma_idle=1
DROP_WIN_END T=26235000 DROP_S_GO=0 cmd_empty=0 cmd_rd_en=0 s_owner=0
RAISE_M_OWNER T=26235000 m_owner=1
S_OWNER_HIGH T=26315000 s_owner=1 cmd_empty=0 cmd_rd_en=1
DROP_S_GO=0
GRANT_S_GO=1
CLASS=POP_GATED
GO_POP_GATE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 46315 ns
```

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
xelab         = -mt off -O0 -L xpm + glbl
wrapper       = run_tb_go_pop_gate_00.bat
```

`UNIT_PASS` = SHA recorded + TB finished. Not existence. Not `pred=664`.
