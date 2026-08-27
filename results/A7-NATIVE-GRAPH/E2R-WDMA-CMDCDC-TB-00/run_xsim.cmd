@echo off
REM E2R-WDMA-CMDCDC-TB-00 — unit XSim of a7ng_wdma_cdc cmd FIFO only
REM Do not redirect to xvlog.log/xelab.log — Vivado also opens those names.
setlocal
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board
set OUT=%ROOT%\results\A7-NATIVE-GRAPH\E2R-WDMA-CMDCDC-TB-00
set XVLOG=C:\2026.1\Vivado\bin\xvlog.bat
set XELAB=C:\2026.1\Vivado\bin\xelab.bat
set XSIM=C:\2026.1\Vivado\bin\xsim.bat
set XILINX_VIVADO=C:\2026.1\Vivado
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set GLBL=C:\2026.1\Vivado\data\verilog\src\glbl.v

cd /d "%OUT%"
if exist xsim.dir rmdir /s /q xsim.dir

echo === xvlog ===
call "%XVLOG%" -sv "%ROOT%\rtl\board\a7ng_wdma_cdc.sv" "%OUT%\tb_e2r_wdma_cmdcdc_00.sv" 1>xvlog_stdout.txt 2>&1
if errorlevel 1 (
  echo xvlog FAILED
  type xvlog_stdout.txt
  exit /b 1
)
call "%XVLOG%" "%GLBL%" 1>xvlog_glbl.txt 2>&1
if errorlevel 1 (
  echo xvlog glbl FAILED
  type xvlog_glbl.txt
  exit /b 1
)

echo === xelab ===
call "%XELAB%" -mt off -O0 tb_e2r_wdma_cmdcdc_00 glbl -s e2r_wdma_cmdcdc -L xpm -timescale 1ns/1ps 1>xelab_stdout.txt 2>&1
if errorlevel 1 (
  echo xelab FAILED
  type xelab_stdout.txt
  exit /b 1
)

echo === xsim ===
call "%XSIM%" e2r_wdma_cmdcdc -R -log xsim.log 1>xsim_stdout.txt 2>&1
set RC=%ERRORLEVEL%
echo === done rc=%RC% ===
findstr /C:"E2R_WDMA_CMDCDC" /C:"M_GO" /C:"S_GO" /C:"SUMMARY" /C:"FIRST_MISSING" /C:"PROBE" xsim_stdout.txt
exit /b %RC%
