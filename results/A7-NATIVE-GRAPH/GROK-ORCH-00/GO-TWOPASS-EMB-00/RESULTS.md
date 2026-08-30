# GO-TWOPASS-EMB-00 — RESULTS

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**PROGRAM:** NO. **JTAG:** NO. **BOARD_PASS:** not claimed.  
**EXISTENCE:** not claimed. **pred=664:** not claimed.

## Verdict

| Field | Value |
|-------|-------|
| CORE SHA256 | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |
| CONTROL (before) | `C47F219DD38C552E1E276D81ECCA0A00F2E5959D1FCD197FF6A8198CD721AE2D` |
| RG_SWITCHES | **1** (≤2) |
| POS_SETS | **1024** |
| TOK_SETS | **1024** |
| First miss | **POS** (`FIRST_MISS_RG=1`) |
| TOK_WITHOUT_MISS | **0** |
| GO_TWOPASS_EMB_00_UNIT_PASS | **YES** (printed) |
| XSIM3_TRANSPORT | FAIL (`GO_COUNT=3456` `DONE_COUNT=1152` `GO_WHILE_BUSY=2304`) — grok-orch tile UNCHANGED |
| BOARD_PASS | not claimed |

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/lm/tiny_gpt803k_core.sv` | CONTROL (ST_EMB interleaved) | `C47F219DD38C552E1E276D81ECCA0A00F2E5959D1FCD197FF6A8198CD721AE2D` |
| `rtl/lm/tiny_gpt803k_core.sv` | CANDIDATE (exact copy, no hand-edit) | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |
| `rtl/lm/weight_tile803k.sv` | UNCHANGED | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` |
| `rtl/lm/a7lm06_pkg.sv` | UNCHANGED | `77B01CBDC4654CF192F35CE6CC378DDEC63C35729BE7AB2D2EA22E98B878AED5` |
| `tests/xsim/tb_go_twopass_emb_00.sv` | module rename + UNIT_PASS display | `41181C2D342713CD27CA93D32013D8CFA370F91A72E26712A82DBF1345179271` |

Source (READ only): `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-close664\rtl\lm\tiny_gpt803k_core.sv`

## Required prints (`xsim.log`)

```text
POS_SETS=1024 TOK_SETS=1024 RG_SWITCHES=1
FIRST_MISS_RG=1 SAW_POS_MISS=1 TOK_WITHOUT_MISS=0 FIRST_MISS_TOK=0
GO_TWOPASS_EMB_00_UNIT_PASS
```

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
xelab         = -mt off -O0 + glbl
wrapper       = run_tb_go_twopass_emb_00.bat
workdir       = results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-TWOPASS-EMB-00/
```

`UNIT_PASS` = SHA recorded + TB finished with POS-then-TOK embedding exact. Not existence. Not `pred=664`. Not BOARD_PASS.
