@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\PHASE2-UART-HS-BIT-00\program_phase2_uart_hs_bit_00_excl.tcl" -log "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\PHASE2-UART-HS-BIT-00\program_phase2_uart_hs_00.log" -journal "D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\PHASE2-UART-HS-BIT-00\program_phase2_uart_hs_00.jou"
exit /b %ERRORLEVEL%
