@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo P2-MIG-PERSIST-CDC-CLOSURE-02 PHYS=4 LABEL=MINHEAP PROGRAM=NO
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%build_p2_mig_persist_cdc_closure_02.tcl" -log "%BAG%vivado_physical.log" -journal "%BAG%vivado_physical.jou"
exit /b %ERRORLEVEL%
