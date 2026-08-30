@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\GO-H2PACK-SOC-00\program_go_h2pack_soc_00_excl.tcl" -log "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\GO-H2PACK-SOC-00\program_h2pack.log" -journal "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\GO-H2PACK-SOC-00\program_h2pack.jou"
exit /b %ERRORLEVEL%
