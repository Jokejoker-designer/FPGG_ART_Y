@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo P2-G1G5-FULLCHIP-COFIT-00 PHYS=4 LABEL=MINHEAP PROGRAM=NO AFAST=249
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_p2_g1g5_fullchip_cofit_00.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
