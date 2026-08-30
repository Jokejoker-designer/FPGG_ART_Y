# QSTAR-CTRL-QHEAD-00 — isolated XSim (ADDON-LAB)

**Date:** 2026-08-29  
**Prereg:** `QSTAR-CTRL-QHEAD-00_PREREG.md`  
**Tree:** grok-orch-00 only  
**DUT:** `qstar_qhead_serial` (`USE_ZERO_WEIGHT_ROM=0`) + `qstar_ctrl` + `qstar_pkg`  
**PROGRAM:** NO. **BOARD_PASS:** not claimed. **SoC instantiate:** none.

This is ADDON-LAB. Not LM-06 golden 744. Not Native-V1 UART `pred=664`.  
No RTL hook was required: eval handshake lives in the TB (`eval_req` → pulse qhead `start` → wait `valid` → `eval_valid`).

## Result

| Gate | Status |
|------|--------|
| `xvlog` `tb_qstar_ctrl_qhead_v0` | **PASS** |
| `xelab` snapshot `tb_qstar_ctrl_qhead_v0` (`-mt off -O0`) | **PASS** |
| `xsim -runall` marker `QSTAR_CTRL_QHEAD_UNIT_PASS` | **PASS** |
| `best_action` | **3** = VERIFY (`QSTAR_A_VERIFY`) |
| qhead-owned `q[3]` unique max | **PASS** `QSTAR_QHEAD_Q3=40` (TB does not poke `q_action`) |
| `qstar_*` on `arty_a7_ng_native_v1_ab_soc_top` | **not instantiated** (by design) |

**H_CANDIDATE held. H_RIVAL falsified.**  
**XSIM = PASS**

## Tool

```text
XILINX_VIVADO = C:\2026.1\Vivado
xsim          = v2026.1 (64-bit)  SW Build 6511674  2026-06-16
```

PATH at run time did not include `xvlog`; tools were invoked after `C:\2026.1\Vivado\settings64.bat`.

## Command (repro)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/xsim_qstar_ctrl_qhead_v0/`  
Wrapper: `run_tb_qstar_ctrl_qhead_v0.bat` (uses `call xvlog.bat` / `xelab.bat` / `xsim.bat`).

```text
call C:\2026.1\Vivado\settings64.bat
xvlog.bat -sv rtl/qstar/qstar_pkg.sv rtl/qstar/qstar_ctrl.sv rtl/qstar/qstar_qhead_serial.sv tests/xsim/tb_qstar_ctrl_qhead_v0.sv
xelab.bat tb_qstar_ctrl_qhead_v0 -s tb_qstar_ctrl_qhead_v0 -timescale 1ns/1ps -mt off -O0
xsim.bat  tb_qstar_ctrl_qhead_v0 -runall
```

## Stimulus (not a TB `q_action` poke)

All `hidden`/`weight`/`bias` start at 0. Then:

- `hidden[0] = 1`
- `weight[3][0] = 40`  (VERIFY row)

Serial MAC: `q[3] = sat16(0 + 1*40) = 40`; every other `q[a] = 0`. VERIFY is the unique max.

Handshake (same VERIFY-win path as `tb_qstar_ctrl_v0`):

1. ctrl `start` → `eval_req`
2. TB pulses qhead `start`, waits `valid`
3. qhead `q_action[]` is wired into ctrl
4. TB pulses `eval_valid`
5. `verify_pass=1`, `memory_hit_i=1`, `contradiction_i=0` → `success=1`, `best_action=3`

## TB transcript (authoritative)

```text
QSTAR_QHEAD_Q3=40
QSTAR_BEST_ACTION=3
QSTAR_NODE_COUNT=1
QSTAR_CTRL_QHEAD_UNIT_PASS
$finish called at time : 10355 ns
```

10355 ns ≈ 8×128 MAC cycles (10 ns clk) plus handshake. These numbers are **not** 664 or 744.

## Explicitly not done

- No instantiate on `arty_a7_ng_native_v1_ab_soc_top`
- No edit of existence CDC / tile / top
- No edit of LM-06 / 01R / 02M golden
- No board program / JTAG / COM12
- No DMA master, no 1024-way token Q-head
- No RTL change under `rtl/qstar/` (handshake is TB-only)
