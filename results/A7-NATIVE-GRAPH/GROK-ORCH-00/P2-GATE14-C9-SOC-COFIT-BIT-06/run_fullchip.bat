@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
cd /d D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\P2-GATE14-C9-SOC-COFIT-BIT-06
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source build_c9_soc_cofit_bit_06.tcl
exit /b %ERRORLEVEL%
