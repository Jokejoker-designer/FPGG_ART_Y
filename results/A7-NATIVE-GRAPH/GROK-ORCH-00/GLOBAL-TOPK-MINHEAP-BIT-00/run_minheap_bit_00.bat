@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo GLOBAL-TOPK-MINHEAP-BIT-00 PROGRAM=NO COM12=NOT_HELD BIT_FIRST
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_minheap_bit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
