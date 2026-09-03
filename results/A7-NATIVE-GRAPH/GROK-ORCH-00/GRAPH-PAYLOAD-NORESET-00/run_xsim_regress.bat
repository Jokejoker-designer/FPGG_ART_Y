@echo off
setlocal
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
set BAG=%~dp0
set ROOT=%BAG%..\..\..\..
set XVLOG=C:\2026.1\Vivado\bin\xvlog.bat
set XELAB=C:\2026.1\Vivado\bin\xelab.bat
set XSIM=C:\2026.1\Vivado\bin\xsim.bat
echo GRAPH-PAYLOAD-NORESET-00 reset/X/stale XSim PROGRAM=NO
cd /d "%BAG%"
call %XVLOG% -sv ^
  "%ROOT%\rtl\native_graph\pkg\a7ng_pkg.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_termgen_lane_fold6.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_scorer_lane.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_scorer_array.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_topk.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_topk_stream_minheap.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_ng02_core.sv" ^
  "%ROOT%\rtl\native_graph\frontier\a7ng_frontier_buckets.sv" ^
  "%ROOT%\tests\xsim\tb_graph_payload_noreset.sv" > "%BAG%xvlog_regress.log" 2>&1
if errorlevel 1 (
  type "%BAG%xvlog_regress.log"
  exit /b 2
)
call %XELAB% tb_graph_payload_noreset -s graph_payload_noreset -timescale 1ns/1ps > "%BAG%xelab_regress.log" 2>&1
if errorlevel 1 (
  type "%BAG%xelab_regress.log"
  exit /b 3
)
call %XSIM% graph_payload_noreset -runall > "%BAG%xsim_regress.log" 2>&1
type "%BAG%xsim_regress.log"
findstr /C:"GRAPH_PAYLOAD_NORESET_XSIM_PASS" "%BAG%xsim_regress.log" >nul
if errorlevel 1 exit /b 5
exit /b 0
