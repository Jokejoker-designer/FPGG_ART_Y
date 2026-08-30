@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo PHASE2-UART-HS-BIT-00 UART_SLIM minheap handshake CONTROL=439CC42D
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_phase2_uart_hs_bit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
