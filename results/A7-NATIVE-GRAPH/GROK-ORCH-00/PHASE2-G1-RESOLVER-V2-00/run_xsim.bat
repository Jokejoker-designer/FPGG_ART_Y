@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
echo PHASE2-G1-RESOLVER-V2-00 XSim PROGRAM=NO
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "%BAG%run_xsim.tcl" -log "%BAG%xsim_master.log" -journal "%BAG%xsim_master.jou"
exit /b %ERRORLEVEL%
