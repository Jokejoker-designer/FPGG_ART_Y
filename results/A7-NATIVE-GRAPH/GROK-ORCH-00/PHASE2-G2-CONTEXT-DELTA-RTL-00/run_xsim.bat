@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
cd /d %~dp0
python audit_ports.py D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\native_graph\learn\a7ng_context_delta.sv
if errorlevel 1 exit /b 2
C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source run_xsim.tcl
exit /b %ERRORLEVEL%
