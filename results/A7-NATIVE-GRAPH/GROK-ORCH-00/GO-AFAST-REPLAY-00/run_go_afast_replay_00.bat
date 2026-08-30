@echo off
REM Existence vehicle XSim on grok-orch. Does not take impl license (xvlog/xelab/xsim only).
REM PROGRAM=NO. cwd tests\xsim for a7lm06_wmem.hex.
setlocal
call C:\2026.1\Vivado\settings64.bat
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00
set BAG=%~dp0
set XSIMDIR=%ROOT%\tests\xsim
set GLBL=C:\2026.1\Vivado\data\verilog\src\glbl.v
cd /d "%XSIMDIR%"
echo GO-AFAST-REPLAY-00 PROGRAM=NO cwd=%CD%
if exist xsim.dir rmdir /s /q xsim.dir
echo === xvlog ===
call xvlog.bat -sv ^
  "%ROOT%\rtl\native_graph\pkg\a7ng_pkg.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_mem_schema_v1.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_scorer_lane.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_scorer_array.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_termgen_lane.sv" ^
  "%ROOT%\rtl\native_graph\scorer\a7ng_termgen_array.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_topk.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_topk_wavefront_global.sv" ^
  "%ROOT%\rtl\native_graph\topk\a7ng_ng02_core.sv" ^
  "%ROOT%\rtl\native_graph\frontier\a7ng_frontier_buckets.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_ddr_soa_axi_bridge.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_soa_plane_engine.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_soa_plane_fetch.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_axi_read_stream.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_cue_soa_wavefront.sv" ^
  "%ROOT%\rtl\native_graph\memory\a7ng_cue_soa_mig_top.sv" ^
  "%ROOT%\rtl\native_graph\integrate\a7ng_lm_graph_arb.sv" ^
  "%ROOT%\rtl\native_graph\lm\a7ng_native_ctx_bind.sv" ^
  "%ROOT%\rtl\native_graph\integrate\a7ng_native_v1_ab_core.sv" ^
  "%ROOT%\rtl\lm\a7lm06_pkg.sv" ^
  "%ROOT%\rtl\lm\isqrt32.sv" ^
  "%ROOT%\rtl\lm\floordiv_s48.sv" ^
  "%ROOT%\rtl\lm\weight_bram803k.sv" ^
  "%ROOT%\rtl\lm\weight_bram_tdp8.sv" ^
  "%ROOT%\rtl\lm\weight_tile803k.sv" ^
  "%ROOT%\rtl\lm\act_ram128k16.sv" ^
  "%ROOT%\rtl\lm\snap_ram4k16.sv" ^
  "%ROOT%\rtl\lm\tiny_gpt803k_core.sv" ^
  "%XSIMDIR%\a7ng_axi_soa_mem_stub.sv" ^
  "%XSIMDIR%\tb_a7ng_native_v1_ab_fast.sv" > "%BAG%xvlog.txt" 2>&1
if errorlevel 1 (type "%BAG%xvlog.txt" & exit /b 2)
call xvlog.bat "%GLBL%" >> "%BAG%xvlog.txt" 2>&1
echo === xelab ===
call xelab.bat tb_a7ng_native_v1_ab_fast glbl -s tb_a7ng_native_v1_ab_fast_sim -L xpm -timescale 1ns/1ps > "%BAG%xelab.txt" 2>&1
if errorlevel 1 (type "%BAG%xelab.txt" & exit /b 3)
echo === xsim ===
call xsim.bat tb_a7ng_native_v1_ab_fast_sim -runall > "%BAG%xsim.log" 2>&1
set XC=%ERRORLEVEL%
type "%BAG%xsim.log"
findstr /C:"A_FAST_LM_BOARD_LANE_XSIM_PASS" /C:"pred=664" "%BAG%xsim.log" >nul
if errorlevel 1 (
  echo GO_AFAST_REPLAY_00_FAIL
  exit /b 5
)
echo GO_AFAST_REPLAY_00_OK pred=664 PROGRAM=NO
exit /b %XC%
