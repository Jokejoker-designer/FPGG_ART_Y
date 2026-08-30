# GO-READY-GATE-00 — CLOSEOUT

**Gate:** `GO-READY-GATE-00`  
**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-READY-GATE-00_PREREG.md`  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE. **JTAG:** NO.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CONTROL top `u_wdma`: `.go(dma_go)`, `.m_axi_arready(arready)`, `.m_axi_rvalid(rvalid)` raw |
| UNKNOWN | After three ANDs with `wdma_owner_ui`, owned start parks in AR; drop owner; raise stub `arready`; does DMA leave AR while `owner_ui=0`? |
| H_CANDIDATE | CLASS=`READY_GATED` (`OWNED_AR=1` and `DROP_AR_ADVANCE=0`) |
| H_RIVAL | `DROP_AR_ADVANCE=1` (AR→R or later while `owner_ui=0`) |
| FALSIFIER | edit CDC / `cmd_wr_en` / `cmd_rd_en`; xvlog full SoC/MIG; program; extra AW/W/B top ports |
| UNIT | one owned `m_go` (`m_wr=0`, addr `28'h000_2000`, bytes=128) then one owner drop; 2000 `s_clk` is one watch window |
| CONTROL | top SHA `E2776512…` raw go/ARREADY/RVALID; CDC `C02F0D54…` POP_GATED (not edited) |

## One ownership law (product RTL)

```text
.go(dma_go && wdma_owner_ui)
.m_axi_arready(arready && wdma_owner_ui)
.m_axi_rvalid(rvalid && wdma_owner_ui)
```

AW/W/B **not** gated on the product instance. CDC / tile dest FSM / QSTAR / MIG / `ddr_tile_dma.sv` **not edited**.

TB does **not** xvlog live full SoC. Bag-local `snap_top_ready_slice.sv` carries the three ANDs + mux bits (`arvalid` / `rready` / `cdc_arready`).

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE (POP_GATED) | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `rtl/board/a7ng_wdma_cdc.sv` | AFTER this gate | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | BEFORE (CONTROL) | `E2776512816C479B0F9E9DA24AF57A7FFB5CF0A2EAA6F31F9211CDAF92C5F790` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | AFTER | `9403BA9C62A9421E3407806A9600F0395FFC2F10BA79C8132CE3948394AA4D02` |
| `rtl/ddr/ddr_tile_dma.sv` | UNCHANGED | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `tests/xsim/tb_go_ready_gate_00.sv` | TB | `CB01EF274D0D08CCD28178B74C56A519CC6139C7932F149053B8A3FE8D5B0C6C` |
| bag `snap_top_ready_slice.sv` | slice | `DE42BACF9AADA0239191EBFAC4B78DA13444D6BBF77B0F5F84221B5725E31777` |

`git diff` on product top: three ANDs + one comment. CDC SHA MATCH before/after this gate.

## Isolated TB

- Instantiates `a7ng_wdma_cdc` + `ddr_tile_dma` + bag-local `snap_top_ready_slice`.
- xvlog: this-tree CDC, this-tree `rtl/ddr/ddr_tile_dma.sv`, bag slice, bag TB. **No** SoC top / MIG.
- Clocks: `m_clk` period 80 ns, `s_clk`/`ui` period 10 ns. Both rst released + XPM recovery.
- Stub `arready` starts 0 so DMA parks in AR while owned; `rvalid` held 0.
- Stimulus: `m_owner=1`, one `m_go` (`m_wr=0`, addr `28'h000_2000`, bytes=128). Wait `dma_st==AR(4)` and `d_arvalid` while `owner_ui=1` → `OWNED_AR=1`. Drop `m_owner`. Wait `owner_ui=0`. Raise stub `arready=1`. Watch 2000 `s_clk`.
- `DROP_AR_ADVANCE=1` iff `dma_st` becomes R(5) or later **while** `owner_ui=0` after the raise.

No QSTAR on SoC. No Cursor paths in xvlog.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`xvlog` + `xelab -mt off -O0 -L xpm` + `glbl` + `xsim -runall`) |
| CLASS | **READY_GATED** (`OWNED_AR=1` and `DROP_AR_ADVANCE=0`) |
| DROP_ST | **4** (AR; did not enter R=5 while `owner_ui=0`) |
| H_CANDIDATE | **SUPPORTED** under this isolated unit |
| H_RIVAL | **FALSIFIED** under this isolated unit |
| UNIT_PASS | **YES** (SHA recorded + TB finished) |
| EXISTENCE | **not claimed** |
| pred=664 | **not claimed** |
| BOARD_PASS | **not claimed** |
| TOP_ELAB | **slice_not_soc** |

`UNIT_PASS` ≠ existence ≠ `pred=664`.

## Required prints (`xsim.log`)

```text
OWNED_AR=1
DROP_AR_ADVANCE=0
DROP_ST=4
CLASS=READY_GATED
GO_READY_GATE_00_UNIT_PASS
```

## Transcript tail (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-READY-GATE-00/`  
Wrapper: `run_tb_go_ready_gate_00.bat`  
Log: `xsim.log`

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
$finish called at time : 26405 ns : File ".../tests/xsim/tb_go_ready_gate_00.sv" Line 305
INFO: [Common 17-206] Exiting xsim at Sat Aug 29 21:15:04 2026...
```

xelab compiled `work.a7ng_wdma_cdc`, `work.snap_top_ready_slice`, `work.ddr_tile_dma`, `work.tb_go_ready_gate_00`, `work.glbl` + XPM. Unused XPM `prog_full` only (pre-existing DUT). After stub raise, `arready=1` but `arready_gated=0`; DMA stayed AR (`st=4`) for the full 2000 `s_clk` window.

## Explicitly not done

- No `open_hw_manager` / program / COM
- No Cursor tree / MAIN STATUS dispatch
- No CDC / `cmd_wr_en` / `cmd_rd_en` edit this gate
- No AW/W/B product-port gate
- No QSTAR instantiate on SoC
- No frozen LM-06 / 01R / 02M rebuild
- No full SoC / MIG xvlog

## NEXT_ONE_UNKNOWN

Not this bag. Do not start the next gate from this closeout.
