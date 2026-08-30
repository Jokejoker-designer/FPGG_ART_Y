# GO-TWOPASS-EMB-00 — CLOSEOUT

**Gate:** `GO-TWOPASS-EMB-00`  
**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-TWOPASS-EMB-00_PREREG.md`  
**PROGRAM:** NO. **JTAG:** NO.

## One file

Exact copy of sealed close664 `tiny_gpt803k_core.sv` over grok-orch core.  
No third schedule. Tile / DMA / pkg **not** edited.

| | SHA256 |
|--|--------|
| CONTROL (ST_EMB interleaved) | `C47F219D…D721AE2D` |
| CANDIDATE (ST_EMB_POS then ST_EMB_TOK) | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |

## Isolated TB

- `tests/xsim/tb_go_twopass_emb_00.sv` (from close664 Test B; module rename + `GO_TWOPASS_EMB_00_UNIT_PASS` display)
- Instantiates `tiny_gpt803k_core #(.SIM_FULL(1'b0))` + same-clk DMA stub
- xvlog: `a7lm06_pkg`, `isqrt32`, `floordiv_s48`, `weight_bram803k`, `weight_bram_tdp8`, `weight_tile803k`, `act_ram128k16`, `snap_ram4k16`, core, TB, `glbl`
- xelab `-mt off -O0`

## Transcript (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-TWOPASS-EMB-00/`  
Log: `xsim.log`

```text
POS_SETS=1024 TOK_SETS=1024 RG_SWITCHES=1 STALL_END=0 LEAVE_EMB=1
FIRST_MISS_RG=1 SAW_POS_MISS=1 TOK_WITHOUT_MISS=0 FIRST_MISS_TOK=0
EMB_EXACT=1
E2R_EMB_TWO_PASS_00_TILE_PASS
XSIM3_TRANSPORT_FAIL
GO_TWOPASS_EMB_00_UNIT_PASS
```

Transport FAIL is extra `dma_go` while busy on **unchanged** grok-orch `weight_tile803k` (`GO_COUNT=3456` vs `DONE_COUNT=1152`). Prereg forbade tile/DMA edit. Prereg UNIT_PASS criteria (RG_SWITCHES≤2, POS then TOK, POS_SETS=TOK_SETS=1024) **met**.

## Not claimed

EXISTENCE · pred=664 · BOARD_PASS · UART · extra BRAM
