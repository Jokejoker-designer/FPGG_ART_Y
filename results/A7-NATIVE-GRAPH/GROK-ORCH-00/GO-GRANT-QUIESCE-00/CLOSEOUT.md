# GO-GRANT-QUIESCE-00 — CLOSEOUT

**Gate:** `GO-GRANT-QUIESCE-00`  
**Date:** 2026-08-30  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-GRANT-QUIESCE-00_PREREG.md`  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE. **JTAG:** NO.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CONTROL drop `else if (!wdma_owner) wdma_owner_grant <= 0` while DMA may still be in AR/R |
| UNKNOWN | After hold law, does grant stay 1 through AR after dest drop, then fall only when cmd_empty && DMA IDLE && AR/R outstanding==0? |
| H_CANDIDATE | CLASS=`QUIESCE_HOLD` |
| H_RIVAL | `GRANT_STUCK` (never drops) or drop while `dma_st!=IDLE` |
| FALSIFIER | edit CDC `cmd_wr_en`/`cmd_rd_en`; xvlog Cursor files; SoC instantiate QSTAR; program leftover LONGBOOT |
| UNIT | owned `m_go` parks in AR; dest drop; pulse `arready` 1 cycle; drain until DMA IDLE; then wait grant=0 |
| CONTROL | top SHA `9403BA9C…` READY_GATED (immediate drop) |

## Product law (`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`)

```text
else if (wdma_owner && r_path_idle) wdma_owner_grant <= 1;
else if (!wdma_owner && wdma_cmd_empty_c && wdma_dma_idle_c && wdma_arr_quiet_c)
  wdma_owner_grant <= 0;
```

Ready-gate ANDs on `u_wdma` kept. CDC / tile / DMA / core / QSTAR **not edited** this gate.

TB first used level `arready=1` (double-count `arr_outst`) and required 8 R beats → CLASS=`GRANT_STUCK`. Fix: pulse `arready` one cycle; wait `dma_st==0`. Rival `GRANT_STUCK` falsified on the retry.

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | UNCHANGED REQUEST_HELD | `E951F1F37D9FE7353103860CA0185D74A1C6D12FB43348C07C91816B093AA582` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | BEFORE (READY) | `9403BA9C62A9421E3407806A9600F0395FFC2F10BA79C8132CE3948394AA4D02` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | AFTER | `57BD7B4D94F160A082734CFFC4A508556CD45FB2A291C2EB9E0DEDFF99EC717F` |
| `rtl/ddr/ddr_tile_dma.sv` | UNCHANGED | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `rtl/lm/tiny_gpt803k_core.sv` | UNCHANGED this gate | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |
| `tests/xsim/tb_go_grant_quiesce_00.sv` | TB | `EAB00426493C3C3B42ABE39B568BAB8766ACE364D7960B464A63AE5999063980` |
| bag `snap_top_grant_quiesce_slice.sv` | slice | `0AF693B6363618E3CAA5BD129CD147890226024CE652523352708ABDA1AF20F7` |

## Isolated TB

- Instantiates this-tree CDC + `ddr_tile_dma` + bag-local `snap_top_grant_quiesce_slice`.
- xvlog: this tree only. **No** full SoC / MIG / QSTAR / Cursor paths.
- Clocks: `m_clk` 80 ns, `s_clk`/`ui` 10 ns.
- Stimulus: owner raise → one owned `m_go` (`m_wr=0`, addr `28'h000_2000`, bytes=128) → park AR → dest drop while AR → `GRANT_HOLD_IN_AR` → 1-cycle `arready` → drain R until `dma_st==0` → wait grant drop.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`xvlog` + `xelab -mt off -O0 -L xpm` + `glbl` + `xsim -runall`) |
| CLASS | **QUIESCE_HOLD** (`GRANT_HOLD_IN_AR=1` and `GRANT_DROP_AFTER_IDLE=1`) |
| H_CANDIDATE | **SUPPORTED** under this isolated unit |
| H_RIVAL GRANT_STUCK | **FALSIFIED** under the pulse-AR / wait-IDLE TB |
| UNIT_PASS | **YES** |
| EXISTENCE | **not claimed** |
| pred=664 | **not claimed** |
| BOARD_PASS | **not claimed** |
| TOP_ELAB | **slice_not_soc** |

`UNIT_PASS` ≠ existence ≠ `pred=664`.

## Transcript tail (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-GRANT-QUIESCE-00/`  
Wrapper: `run_tb_go_grant_quiesce_00.bat`  
Log: `xsim.log`

```text
GRANT_HOLD_IN_AR=1
R_BEATS T=8155000 accepted=7 dma_st=0 arr_outst=0 grant=1
GRANT_AFTER_IDLE T=8440000 grant=0 i=4 idle_c=1 empty_c=1 quiet_c=1
CLASS=QUIESCE_HOLD
GO_GRANT_QUIESCE_00_UNIT_PASS
```
