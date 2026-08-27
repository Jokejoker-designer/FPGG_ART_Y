@echo off
REM E2R-RPATH-IDLE-CXSIM-00 — unit XSim: four r_path_idle constituents
REM Do not redirect to xvlog.log/xelab.log — Vivado also opens those names.
REM No board. No bitstream. No vivado.exe impl writer.
setlocal
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board
set OUT=%ROOT%\results\A7-NATIVE-GRAPH\E2R-RPATH-IDLE-CXSIM-00
set XVLOG=C:\2026.1\Vivado\bin\xvlog.bat
set XELAB=C:\2026.1\Vivado\bin\xelab.bat
set XSIM=C:\2026.1\Vivado\bin\xsim.bat
set XILINX_VIVADO=C:\2026.1\Vivado
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic

cd /d "%OUT%"
if exist xsim.dir rmdir /s /q xsim.dir

copy /Y "%ROOT%\tests\xsim\tb_e2r_rpath_idle_cxsim_00.sv" "%OUT%\tb_e2r_rpath_idle_cxsim_00.sv" >nul

echo === xvlog ===
call "%XVLOG%" -sv "%ROOT%\rtl\native_graph\memory\a7ng_ddr_soa_axi_bridge.sv" "%OUT%\tb_e2r_rpath_idle_cxsim_00.sv" 1>xvlog_stdout.txt 2>&1
findstr /C:"ERROR:" xvlog_stdout.txt >nul
if not errorlevel 1 (
  echo xvlog FAILED
  type xvlog_stdout.txt
  exit /b 1
)

echo === xelab ===
call "%XELAB%" -mt off -O0 tb_e2r_rpath_idle_cxsim_00 -s e2r_rpath_idle_cxsim_00 -timescale 1ns/1ps 1>xelab_stdout.txt 2>&1
if errorlevel 1 (
  echo xelab FAILED
  type xelab_stdout.txt
  exit /b 1
)

echo === xsim ===
call "%XSIM%" e2r_rpath_idle_cxsim_00 -R -log xsim.log 1>xsim_stdout.txt 2>&1
set RC=%ERRORLEVEL%
echo === done rc=%RC% ===
findstr /C:"E2R_RPATH" /C:"PROBE" /C:"PHASE_" /C:"WIRE_" /C:"C_FIX" /C:"VERDICT" /C:"NEXT_" /C:"XSIM=" /C:"EXISTENCE" /C:"RESET" xsim_stdout.txt
exit /b %RC%
