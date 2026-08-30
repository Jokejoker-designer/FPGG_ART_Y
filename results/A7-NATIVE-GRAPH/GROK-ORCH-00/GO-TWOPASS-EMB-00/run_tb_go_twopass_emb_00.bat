@echo off
REM GO-TWOPASS-EMB-00 — SIM_FULL=0 two-pass embedding (POS then TOK)
REM PROGRAM=NO. No JTAG. One file: rtl/lm/tiny_gpt803k_core.sv sealed 355182A7...
REM xelab -mt off -O0. Instantiates tiny_gpt803k_core SIM_FULL=0 + DMA stub.
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
echo === xvlog DUT+TB ===
call xvlog.bat -sv "%ROOT%\rtl\lm\a7lm06_pkg.sv" "%ROOT%\rtl\lm\isqrt32.sv" "%ROOT%\rtl\lm\floordiv_s48.sv" "%ROOT%\rtl\lm\weight_bram803k.sv" "%ROOT%\rtl\lm\weight_bram_tdp8.sv" "%ROOT%\rtl\lm\weight_tile803k.sv" "%ROOT%\rtl\lm\act_ram128k16.sv" "%ROOT%\rtl\lm\snap_ram4k16.sv" "%ROOT%\rtl\lm\tiny_gpt803k_core.sv" "%ROOT%\tests\xsim\tb_go_twopass_emb_00.sv"
if errorlevel 1 exit /b 2
echo === xvlog glbl ===
call xvlog.bat "%GLBL%"
if errorlevel 1 exit /b 2
echo === xelab ===
call xelab.bat -mt off -O0 tb_go_twopass_emb_00 glbl -s tb_go_twopass_emb_00 -timescale 1ns/1ps
if errorlevel 1 exit /b 3
echo === xsim ===
call xsim.bat tb_go_twopass_emb_00 -runall
if errorlevel 1 exit /b 4
exit /b 0
