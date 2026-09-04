@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
cd /d D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00
echo %DATE% %TIME% START pid=%RANDOM% >> results\A7-NATIVE-GRAPH\GROK-ORCH-00\U2R-RESOURCE-MARGIN-RECOVERY-00\launcher.out
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -log results\A7-NATIVE-GRAPH\GROK-ORCH-00\U2R-RESOURCE-MARGIN-RECOVERY-00\vivado_u2r.log -journal results\A7-NATIVE-GRAPH\GROK-ORCH-00\U2R-RESOURCE-MARGIN-RECOVERY-00\vivado_u2r.jou -source results\A7-NATIVE-GRAPH\GROK-ORCH-00\U2R-RESOURCE-MARGIN-RECOVERY-00\build_u2r_fullchip.tcl
echo EXIT=%ERRORLEVEL% %DATE% %TIME% >> results\A7-NATIVE-GRAPH\GROK-ORCH-00\U2R-RESOURCE-MARGIN-RECOVERY-00\launcher.out
endlocal
exit /b %ERRORLEVEL%
