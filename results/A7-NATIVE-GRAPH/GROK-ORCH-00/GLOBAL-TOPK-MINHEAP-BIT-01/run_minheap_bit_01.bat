@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo GLOBAL-TOPK-MINHEAP-BIT-01 PROGRAM=NO control_set_merge
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_minheap_bit_01.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
