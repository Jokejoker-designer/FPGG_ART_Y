@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo GO-H2NOPOISON-SOC-00 PROGRAM=NO COM12=CURSOR BIT_FIRST
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_go_h2nopoison_soc_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
