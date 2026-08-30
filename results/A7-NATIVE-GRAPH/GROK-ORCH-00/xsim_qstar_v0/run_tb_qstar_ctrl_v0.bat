@echo off
setlocal
call C:\2026.1\Vivado\settings64.bat
cd /d "%~dp0"
echo XILINX_VIVADO=%XILINX_VIVADO%
where xvlog
where xelab
where xsim
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00
call xvlog.bat -sv "%ROOT%\rtl\qstar\qstar_pkg.sv" "%ROOT%\rtl\qstar\qstar_ctrl.sv" "%ROOT%\tests\xsim\tb_qstar_ctrl_v0.sv"
if errorlevel 1 exit /b 2
call xelab.bat tb_qstar_ctrl_v0 -s tb_qstar_ctrl_v0 -timescale 1ns/1ps -mt off -O0
if errorlevel 1 exit /b 3
call xsim.bat tb_qstar_ctrl_v0 -runall
if errorlevel 1 exit /b 4
exit /b 0
