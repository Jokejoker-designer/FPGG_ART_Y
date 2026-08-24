# WAITING_BOARD — mig_h_rival (optional silicon)

**Status:** MIG_XSIM stall metrics **archived** (`MIG_SWEEP_ROW.md`, `xsim_mig_rival.log`). H_RIVAL **FALSIFIED** under Digilent AXI + ddr3_model.

**Board silicon ddr_feed stall** remains optional / deferred (not required to close the synthetic-only rival).

## Exact next command (re-run MIG_XSIM)

```powershell
cd D:\Jetking_sem4\SEM_4\arty-a7-online-lm
python results\A7-NATIVE-GRAPH\MIG-RIVAL\gen_prj.py
Remove-Item -Recurse -Force xsim.dir -ErrorAction SilentlyContinue
& C:\2026.1\Vivado\bin\xvlog.bat -prj results\A7-NATIVE-GRAPH\MIG-RIVAL\mig_feed_xsim.prj -i vivado\ip\mig_7series_0\mig_7series_0\example_design\sim
# REQUIRED: -O0 (Vivado 2026.1 default xelab ACCESS_VIOLATION)
& C:\2026.1\Vivado\bin\xelab.bat -mt off -O0 tb_a7ng_ddr_feed_mig glbl -s tb_a7ng_ddr_feed_mig -L unisims_ver -L unimacro_ver -L secureip -timescale 1ps/1ps
& C:\2026.1\Vivado\bin\xsim.bat tb_a7ng_ddr_feed_mig -runall
# Expect: MIG_CALIB_COMPLETE, MIG_SWEEP_ROW..., A7NG_MIG_RIVAL_XSIM_PASS
```

## Exact next command (BOARD — optional)

```text
1. Implement ddr_feed stall UART on Digilent AXI MIG SoC (do not overwrite frozen LM-06/01R/02M/A0.3).
2. Program Arty A7-100T serial 210319BE776EA.
3. Capture (1,1) and (4,8) stall_frac / recs/cycle / DROP.
4. Compare to MIG_XSIM + CONTROL; do not invent GB/s. No BOARD_PASS from this alone.
```

## Hard rules

- Do **not** hand-edit `mig.prj`.
- Do **not** declare BOARD_PASS.
- Do **not** equate synthetic 0.475410 with MIG/board stall.
