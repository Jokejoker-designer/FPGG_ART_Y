@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo GRAPH-PAYLOAD-NORESET-BIT-00 PHYS=4 LABEL=MINHEAP PROGRAM=NO
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_graph_payload_noreset_bit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
