# GO-REQUEST-PENDING-00 — RESULTS

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e` + hold FSM on CDC  
**PROGRAM:** NO. **JTAG:** NO. **BOARD_PASS:** not claimed.  
**EXISTENCE:** not claimed. **pred=664:** not claimed.

## CLASS

**REQUEST_HELD**

## Required prints (`xsim.log`)

```text
CLASS=REQUEST_HELD
CMD_WR_COUNT=1
S_GO_COUNT=1
PAYLOAD_MATCH=1
UNOWNED_S_GO=0
UNOWNED_FALSE_AR=0
GO_REQUEST_PENDING_00_UNIT_PASS
```

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE (CONTROL, POP_GATED live-write) | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `rtl/board/a7ng_wdma_cdc.sv` | AFTER (hold FSM) | `E951F1F37D9FE7353103860CA0185D74A1C6D12FB43348C07C91816B093AA582` |
| `rtl/ddr/ddr_tile_dma.sv` | UNCHANGED | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `tests/xsim/tb_go_request_pending_00.sv` | TB | `1EF8712C65CF8724D96D06E4C34F2AF8DDC1D6CA4038DBCCBDC0CA40802AFC52` |

CONTROL law: `cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full`  
AFTER law: `cmd_wr_en = m_rst_n && cmd_accept` with `cmd_accept = cmd_hold_valid && m_owner && !cmd_full`  
POP: `cmd_rd_en && s_owner` **not edited**.

## Cases

| Case | Result |
|------|--------|
| A delayed grant | **PASS** `CMD_WR_COUNT=1` `S_GO_COUNT=1` `PAYLOAD_MATCH=1` `DMA_LEFT_IDLE=1` (`dma_st=4` AR) `UNOWNED_S_GO=0` `UNOWNED_FALSE_AR=0` |
| B cmd_full | **PASS** (XPM `full=1` after `n_fill=15`; 16th request held, `CMD_WR_COUNT=0`, no hierarchical force) |
| C never grant | **PASS** `CMD_WR_COUNT=0` `S_GO_COUNT=0` hold stays 1, DMA IDLE |
| D duplicate | **PASS** `overflow=1` first payload kept `0000200000000080`, `CMD_WR_COUNT=0` |

## XSim transcript tail

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-REQUEST-PENDING-00/`  
Wrapper: `run_tb_go_request_pending_00.bat`

```text
CLASS=REQUEST_HELD
CMD_WR_COUNT=1
S_GO_COUNT=1
PAYLOAD_MATCH=1
UNOWNED_S_GO=0
UNOWNED_FALSE_AR=0
DMA_LEFT_IDLE=1
CASE_B=PASS
GO_REQUEST_PENDING_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 50360 ns
```

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
xelab         = -mt off -O0 -L xpm + glbl
wrapper       = run_tb_go_request_pending_00.bat
```

`UNIT_PASS` = SHA recorded + TB finished. Not existence. Not `pred=664`.
