@echo off
REM GO-READY-GATE-00 — composition XSim: CDC + ddr_tile_dma + bag-local ready slice
REM PROGRAM=NO. No JTAG. No full SoC / MIG. CDC not edited.
setlocal
call C:\2026.1\Vivado\settings64.bat
cd /d "%~dp0"
echo XILINX_VIVADO=%XILINX_VIVADO%
where xvlog
where xelab
where xsim
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00
set GLBL=C:\2026.1\Vivado\data\verilog\src\glbl.v
if exist xsim.dir rmdir /s /q xsim.dir
echo === xvlog DUT+slice+TB ===
call xvlog.bat -sv "%ROOT%\rtl\board\a7ng_wdma_cdc.sv" "%ROOT%\rtl\ddr\ddr_tile_dma.sv" "%~dp0snap_top_ready_slice.sv" "%ROOT%\tests\xsim\tb_go_ready_gate_00.sv"
if errorlevel 1 exit /b 2
echo === xvlog glbl ===
call xvlog.bat "%GLBL%"
if errorlevel 1 exit /b 2
echo === xelab ===
call xelab.bat -mt off -O0 tb_go_ready_gate_00 glbl -s tb_go_ready_gate_00 -L xpm -timescale 1ns/1ps
if errorlevel 1 exit /b 3
echo === xsim ===
call xsim.bat tb_go_ready_gate_00 -runall
if errorlevel 1 exit /b 4
exit /b 0
