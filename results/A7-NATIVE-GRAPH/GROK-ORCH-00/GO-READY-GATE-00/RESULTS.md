# GO-READY-GATE-00 — RESULTS

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e` + POP_GATED CDC + one-law ready-gate  
**PROGRAM:** NO. **JTAG:** NO. **BOARD_PASS:** not claimed.  
**EXISTENCE:** not claimed. **pred=664:** not claimed.

## CLASS

**READY_GATED**

## Required prints (`xsim.log`)

```text
OWNED_AR=1
DROP_AR_ADVANCE=0
DROP_ST=4
CLASS=READY_GATED
GO_READY_GATE_00_UNIT_PASS
```

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE/AFTER this gate | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | BEFORE (CONTROL) | `E2776512816C479B0F9E9DA24AF57A7FFB5CF0A2EAA6F31F9211CDAF92C5F790` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | AFTER (three ANDs) | `9403BA9C62A9421E3407806A9600F0395FFC2F10BA79C8132CE3948394AA4D02` |
| `rtl/ddr/ddr_tile_dma.sv` | UNCHANGED | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |

CONTROL law: `.go(dma_go)`, `.m_axi_arready(arready)`, `.m_axi_rvalid(rvalid)`  
AFTER law: `.go(dma_go && wdma_owner_ui)`, `.m_axi_arready(arready && wdma_owner_ui)`, `.m_axi_rvalid(rvalid && wdma_owner_ui)`

CDC not edited. `cmd_wr_en` / `cmd_rd_en` not edited. AW/W/B not gated. No QSTAR / frozen LM-06/01R/02M.

## XSim transcript tail

```text
GO-READY-GATE-00 START m_period=80ns s_period=10ns TOP_ELAB=slice_not_soc
RESET_RELEASED T=1960000
RECOVERY T=5955000 cmd_empty=1 cmd_wr_en=0 cmd_rd_en=0 dma_st=0
M_OWNER_RAISE T=5955000
OWNER_UI_1 T=5995000 arready=0 rvalid=0
S_GO_CYCLE T=6275000 dma_st=0 owner_ui=1 wr=0 addr=0002000 bytes=128 go_gated=1 arready=0 arready_gated=0
OWNED_AR=1 T=6295000 dma_st=4 d_arvalid=1 owner_ui=1 arready=0 arready_gated=0
M_OWNER_DROP T=6360000 keep_arready=0
OWNER_DROPPED T=6395000 dma_st=4 d_arvalid=1 arready=0 arready_gated=0
STUB_ARREADY_RAISE T=6405000 rvalid=0 owner_ui=0 arready_gated=0
DROP_WATCH T=6415000 i=0 dma_st=4 d_arvalid=1 arready=1 arready_gated=0 owner_ui=0
DROP_WATCH T=26405000 i=1999 dma_st=4 d_arvalid=1 arready=1 arready_gated=0 owner_ui=0
OWNED_AR=1
DROP_AR_ADVANCE=0
DROP_ST=4
CLASS=READY_GATED
GO_READY_GATE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 26405 ns
```

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
xelab         = -mt off -O0 -L xpm + glbl
wrapper       = run_tb_go_ready_gate_00.bat
TOP_ELAB      = slice_not_soc
```

`UNIT_PASS` = SHA recorded + TB finished. Not existence. Not `pred=664`.
