@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo RESOURCE-CLOSURE-BIT-00 PROGRAM=NO CONTROL=B0F42C11
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_resource_closure_bit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
