$env:XILINXD_LICENSE_FILE = 'D:\Xilinx\licenses\vivado_basic.lic'
$log = 'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\results\A7-NATIVE-GRAPH\E2R-UART-MGO-HB-FIX-00\build_stdout_resume2.log'
$exitf = 'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\results\A7-NATIVE-GRAPH\E2R-UART-MGO-HB-FIX-00\build_exitcode.txt'
cmd /c "call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\vivado\tcl\build_e2r_uart_mgo_hb_fix_00_resume.tcl > $log 2>&1"
"RESUME2_EXIT=$LASTEXITCODE" | Set-Content $exitf
