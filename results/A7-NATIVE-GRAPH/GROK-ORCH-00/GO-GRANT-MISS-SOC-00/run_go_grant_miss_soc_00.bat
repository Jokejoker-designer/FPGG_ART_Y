@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
set TCL=%BAG%build_go_grant_miss_soc_00.tcl
set LOG=%BAG%vivado_physical.log
set JOU=%BAG%vivado_physical.jou
echo GO-GRANT-MISS-SOC-00 PROGRAM=NO until Cursor returns COM12
echo TCL=%TCL%
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%TCL%" -log "%LOG%" -journal "%JOU%"
exit /b %ERRORLEVEL%
