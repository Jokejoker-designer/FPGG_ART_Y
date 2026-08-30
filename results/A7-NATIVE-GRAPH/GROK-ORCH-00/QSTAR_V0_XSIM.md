# QSTAR-HEURISTIC-V0 — isolated XSim (`tb_qstar_ctrl_v0`)

**Date:** 2026-08-29  
**Tree:** `research/native-ai-v1-grok-orch-00`  
**DUT:** `qstar_ctrl` + `qstar_pkg` only  
**PROGRAM:** NO. **BOARD_PASS:** not claimed. **SoC instantiate:** none.

This is ADDON-LAB. Not LM-06 golden 744. Not Native-V1 UART `pred=664`.

## Result

| Gate | Status |
|------|--------|
| `xvlog` `tb_qstar_ctrl_v0` | **PASS** |
| `xelab` snapshot `tb_qstar_ctrl_v0` (`-mt off -O0`) | **PASS** |
| `xsim -runall` marker `QSTAR_V0_UNIT_PASS` | **PASS** |
| `qstar_*` on `arty_a7_ng_native_v1_ab_soc_top` | **not instantiated** (by design) |

**XSIM = PASS**

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
```

PATH at run time did not include `xvlog`; tools were invoked after `C:\2026.1\Vivado\settings64.bat`.

## Command (repro)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/xsim_qstar_v0/`  
Wrapper: `run_tb_qstar_ctrl_v0.bat` (uses `call xvlog.bat` / `xelab.bat` / `xsim.bat`).

```text
call C:\2026.1\Vivado\settings64.bat
xvlog.bat -sv rtl/qstar/qstar_pkg.sv rtl/qstar/qstar_ctrl.sv tests/xsim/tb_qstar_ctrl_v0.sv
xelab.bat tb_qstar_ctrl_v0 -s tb_qstar_ctrl_v0 -timescale 1ns/1ps -mt off -O0
xsim.bat  tb_qstar_ctrl_v0 -runall
```

## TB transcript (authoritative)

```text
QSTAR_BEST_ACTION=3
QSTAR_NODE_COUNT=1
QSTAR_GOAL_ID=1
QSTAR_V0_UNIT_PASS
$finish called at time : 105 ns
```

`best_action=3` is VERIFY (`QSTAR_A_VERIFY`). TB drives `q_action[3]=40` as the unique max; VERIFY path then `verify_pass=1`, `memory_hit_i=1`, `contradiction_i=0` → `success=1`.

These numbers are **not** 664 or 744.

## Host MAC law (qhead serial — not this TB)

`qstar_qhead_serial` is ADDON-LAB RTL + host oracle only. It was **not** elaborated in this XSim run (out of scope for `tb_qstar_ctrl_v0`).

```text
python -m pytest tests/qstar/test_heuristic_v0.py tests/qstar/test_qhead_serial.py -q
................                                                         [100%]
16 passed in 0.19s
```

MAC law: INT8 hidden[128] × INT8 W[8][128], 1 MAC/step, INT16 acc, `sat16` per add. Zero-weight ROM degenerates to `q[a] = sat16(bias[a])`. Not LM logits.

## Explicitly not done

- No instantiate on `arty_a7_ng_native_v1_ab_soc_top`
- No edit of LM-06 / 01R / 02M golden
- No board program / JTAG / COM12
- No DMA master, no 1024-way token Q-head
