@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo PHASE2-G1-RESOLVER-V2-00 OOC PROGRAM=NO
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%run_ooc.tcl" -log "%BAG%ooc.log" -journal "%BAG%ooc.jou"
exit /b %ERRORLEVEL%
