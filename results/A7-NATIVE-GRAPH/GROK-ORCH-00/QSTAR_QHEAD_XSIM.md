# QSTAR serial Q-head — isolated XSim

**Date:** 2026-08-29  
**Tree:** `research/native-ai-v1-grok-orch-00` only  
**DUT:** `qstar_qhead_serial` + `qstar_pkg`  
**PROGRAM:** NO. **SoC instantiate:** none. Not 664 / 744.

## Result

| Gate | Status |
|------|--------|
| `xvlog` `tb_qstar_qhead_serial_v0` | **PASS** |
| `xelab` `-mt off -O0` | **PASS** |
| `xsim -runall` | **PASS** `QSTAR_QHEAD_V0_UNIT_PASS` at 20535 ns |
| zero-weight ROM vs `sat16(bias)` | **PASS** |
| hidden=1, W=1 → q[a]=128 | **PASS** |

XSIM = PASS. Not existence.

## Repro

```text
results/A7-NATIVE-GRAPH/GROK-ORCH-00/xsim_qstar_qhead_v0/run_tb_qstar_qhead_serial_v0.bat
```

Host oracle remains `python/qstar/qhead_serial.py` (pytest on this tree).
