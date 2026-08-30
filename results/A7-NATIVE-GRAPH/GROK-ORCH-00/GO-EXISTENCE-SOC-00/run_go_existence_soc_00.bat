@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
set TCL=%BAG%build_go_existence_soc_00.tcl
set LOG=%BAG%vivado_physical.log
set JOU=%BAG%vivado_physical.jou
echo GO-EXISTENCE-SOC-00 PROGRAM=NO
echo TCL=%TCL%
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%TCL%" -log "%LOG%" -journal "%JOU%"
exit /b %ERRORLEVEL%
