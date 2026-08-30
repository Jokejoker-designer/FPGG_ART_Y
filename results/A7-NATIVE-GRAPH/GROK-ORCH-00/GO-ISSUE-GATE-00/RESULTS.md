# GO-ISSUE-GATE-00 — RESULTS

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e` + one-wire CDC  
**PROGRAM:** NO. **JTAG:** NO. **BOARD_PASS:** not claimed.  
**EXISTENCE:** not claimed. **pred=664:** not claimed.

## CLASS

**ISSUE_GATED**

## Required prints (`xsim.log`)

```text
CMD_WR_UNOWNED=0
CMD_WR_OWNED=1
CLASS=ISSUE_GATED
GO_ISSUE_GATE_00_UNIT_PASS
```

## SHA256 `rtl/board/a7ng_wdma_cdc.sv`

| When | SHA256 |
|------|--------|
| BEFORE (CONTROL) | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` |
| AFTER (one wire) | `A036F21644EF29E4DA9A9702D01CE26E7AB6994EEFF634A0110F56352DD56E3F` |

CONTROL law: `cmd_wr_en = m_rst_n && m_go && !cmd_full`  
AFTER law: `cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full`

`cmd_rd_en` not edited. No tile / top / DMA / QSTAR / frozen LM-06/01R/02M.

## XSim transcript tail

```text
GO-ISSUE-GATE-00 START m_period=80ns s_period=10ns
RESET_RELEASED T=1960000
RECOVERY T=5955000 cmd_full=0 cmd_wr_en=0
PULSE_UNOWNED T=6040000 m_owner=0 m_go=1 cmd_wr_en=0 cmd_full=0
PULSE_OWNED T=6920000 m_owner=1 m_go=1 cmd_wr_en=1 cmd_full=0
CMD_WR_UNOWNED=0
CMD_WR_OWNED=1
CLASS=ISSUE_GATED
GO_ISSUE_GATE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 7 us
```

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
xelab         = -mt off -O0 -L xpm + glbl
wrapper       = run_tb_go_issue_gate_00.bat
```

`UNIT_PASS` = SHA recorded + TB finished. Not existence. Not `pred=664`.
