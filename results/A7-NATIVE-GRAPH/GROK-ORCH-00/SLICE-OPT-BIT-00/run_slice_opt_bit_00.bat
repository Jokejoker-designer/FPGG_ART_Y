@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo SLICE-OPT-BIT-00 PROGRAM=NO UART_SLIM CONTROL=439CC42D
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_slice_opt_bit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
