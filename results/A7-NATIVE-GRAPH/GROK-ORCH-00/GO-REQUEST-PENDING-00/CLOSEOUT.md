# GO-REQUEST-PENDING-00 — CLOSEOUT

**Gate:** `GO-REQUEST-PENDING-00`  
**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-REQUEST-PENDING-00_PREREG.md`  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE. **JTAG:** NO.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CONTROL live-write `cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full` drops a 1-cycle unowned `m_go` |
| UNKNOWN | After m_clk hold FSM, does delayed grant print exactly one FIFO write and one `s_go` with the latched payload, DMA leaving IDLE? |
| H_CANDIDATE | CLASS=`REQUEST_HELD` |
| H_RIVAL | unowned pulse lost (`CMD_WR_COUNT=0` after grant) or leak (`UNOWNED_S_GO=1` / extra writes) |
| FALSIFIER | edit `cmd_rd_en`; xvlog Cursor files; SoC instantiate; program |
| UNIT | A delayed grant + C never-grant + D duplicate; B cmd_full |
| CONTROL | `a7ng_wdma_cdc.sv` SHA `C02F0D54…DDEE` (POP_GATED live-write) |

## One law (only RTL edit)

`rtl/board/a7ng_wdma_cdc.sv` only. Replace live-write with hold FSM (`m_clk`):

```text
wire cmd_accept = cmd_hold_valid && m_owner && !cmd_full;
assign cmd_wdata = cmd_hold_data;
assign cmd_wr_en = m_rst_n && cmd_accept;
```

Removed `assign cmd_wdata = {m_wr,m_addr,m_bytes};`.  
POP `cmd_rd_en && s_owner` **kept**. tile / top / DMA / QSTAR / frozen 01R/02M/LM-06: **not edited**.

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE (CONTROL) | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `rtl/board/a7ng_wdma_cdc.sv` | AFTER | `E951F1F37D9FE7353103860CA0185D74A1C6D12FB43348C07C91816B093AA582` |
| `rtl/ddr/ddr_tile_dma.sv` | UNCHANGED | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `tests/xsim/tb_go_request_pending_00.sv` | TB | `1EF8712C65CF8724D96D06E4C34F2AF8DDC1D6CA4038DBCCBDC0CA40802AFC52` |

## Isolated TB

- Instantiates `a7ng_wdma_cdc` + `ddr_tile_dma` (SHA `20BAE36E`).
- xvlog: this-tree CDC, this-tree `rtl/ddr/ddr_tile_dma.sv`, this TB, `glbl.v`. **No** SoC top / MIG.
- Clocks: `m_clk` period 80 ns, `s_clk`/`ui` period 10 ns. Both rst released + XPM recovery.
- AXI stub: `arready=0` so DMA parks in AR after leaving IDLE.
- Case A: `m_owner=0`, 1-cycle `m_go` (`wr=0`, addr `28'h000_2000`, bytes=128), then raise owner.
- Case B: hold `s_busy` so pop is blocked; fill XPM until `cmd_full`; extra `m_go` must not write.
- Case C: owner stays 0; watch 2000 `s_clk`.
- Case D: second `m_go` while pending → overflow sticky, first payload kept.

No QSTAR on SoC. No Cursor paths in xvlog.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`xvlog` + `xelab -mt off -O0 -L xpm` + `glbl` + `xsim -runall`) |
| CLASS | **REQUEST_HELD** (`CMD_WR_COUNT=1` `S_GO_COUNT=1` `PAYLOAD_MATCH=1` `UNOWNED_S_GO=0` `UNOWNED_FALSE_AR=0`) |
| Case A | **PASS** (hold then one write / one `s_go`; `dma_st` IDLE→AR) |
| Case B | **PASS** (`cmd_full=1` after 15 accepted fills; held 16th, no force) |
| Case C | **PASS** (no wr, no `s_go`) |
| Case D | **PASS** (`overflow=1`, first payload kept, not two writes) |
| H_CANDIDATE | **SUPPORTED** under this isolated unit |
| H_RIVAL | **FALSIFIED** under this isolated unit |
| UNIT_PASS | **YES** (SHA recorded + TB finished) |
| EXISTENCE | **not claimed** |
| pred=664 | **not claimed** |
| BOARD_PASS | **not claimed** |

`UNIT_PASS` ≠ existence ≠ `pred=664`.

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

## Transcript tail (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-REQUEST-PENDING-00/`  
Wrapper: `run_tb_go_request_pending_00.bat`  
Log: `xsim.log`

```text
GO-REQUEST-PENDING-00 START m_period=80ns s_period=10ns
RESET_RELEASED T=1960000
RECOVERY T=5955000 cmd_full=0 cmd_empty=1 hold_v=0 overflow=0 dma_st=0
CASE_A_PULSE_UNOWNED T=5955000 wr=0 addr=0002000 bytes=128
CASE_A_HELD T=6120000 hold_ok=1 hold_v=1 hold_data=0000200000000080 wr_en=0 owner=0 wr_count=0
CASE_A_GRANT T=6840000 hold_v=1 cmd_accept=0 cmd_full=0
S_GO_CYCLE T=7075000 s_owner=1 wr=0 addr=0002000 bytes=128 dma_st=0
CASE_A_WAITEND T=7085000 wr_count=1 s_go_count=1 payload=1 dma_st=4 left_idle=1 s_owner=1 empty=1
CASE_A_RESULT pass=1 CMD_WR_COUNT=1 S_GO_COUNT=1 PAYLOAD_MATCH=1 DMA_LEFT_IDLE=1 UNOWNED_S_GO=0 UNOWNED_FALSE_AR=0
RESET_RELEASED T=9080000
RECOVERY T=13075000 cmd_full=0 cmd_empty=1 hold_v=0 overflow=0 dma_st=0
CASE_C_PULSE_NEVER_GRANT T=13075000
CASE_C_WATCHEND T=33235000 hold_ok=1 hold_v=1 wr_count=0 s_go_count=0 dma_st=0 overflow=0
CASE_C_RESULT pass=1 CMD_WR_COUNT=0 S_GO_COUNT=0
RESET_RELEASED T=35160000
RECOVERY T=39155000 cmd_full=0 cmd_empty=1 hold_v=0 overflow=0 dma_st=0
CASE_D_FIRST_PULSE T=39155000
CASE_D_SECOND_PULSE T=39320000 hold_v=1 hold_data=0000200000000080
CASE_D_AFTER T=39560000 overflow=1 hold_data=0000200000000080 wr_count=0 s_go_count=0
CASE_D_RESULT pass=1 overflow=1 first_kept=1 CMD_WR_COUNT=0
RESET_RELEASED T=41560000
RECOVERY T=45555000 cmd_full=0 cmd_empty=1 hold_v=0 overflow=0 dma_st=0
CASE_B_FILL T=49480000 n_fill=15 cmd_full=1 hold_v=0 wr_count=15 empty=0
CASE_B_RESULT status=PASS pass=1 forced=0 CMD_WR_COUNT=0 hold_v=1 overflow=0 full=1
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
$finish called at time : 50360 ns : File ".../tests/xsim/tb_go_request_pending_00.sv" Line 461
INFO: [Common 17-206] Exiting xsim at Sat Aug 29 21:32:02 2026...
```

xelab compiled `work.a7ng_wdma_cdc`, `work.ddr_tile_dma`, `work.tb_go_request_pending_00`, `work.glbl` + XPM. Unused XPM `prog_full` only (pre-existing DUT). Hierarchical probes succeeded. Case A grant display `cmd_accept=0` is same-timestep TB vs DUT combo; the next `m_clk` accepted (`CMD_WR_COUNT=1`).

## Explicitly not done

- No `open_hw_manager` / program / COM
- No Cursor tree / MAIN STATUS dispatch
- No `cmd_rd_en` edit this gate
- No QSTAR instantiate on SoC
- No frozen LM-06 / 01R / 02M rebuild
- No tile / top RTL
- No full SoC / MIG xvlog

## NEXT_ONE_UNKNOWN

Not this bag. Do not start the next gate from this closeout.
