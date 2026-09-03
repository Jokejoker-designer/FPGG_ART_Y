@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
cd /d %~dp0
C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source run_ooc.tcl
exit /b %ERRORLEVEL%
