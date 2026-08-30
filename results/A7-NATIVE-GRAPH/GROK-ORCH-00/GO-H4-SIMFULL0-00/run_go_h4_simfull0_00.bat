@echo off
REM H4: SIM_FULL=0 full forward, hex DMA stub. No board. PROGRAM=NO.
setlocal
call C:\2026.1\Vivado\settings64.bat
set ROOT=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00
set BAG=%~dp0
set XSIMDIR=%ROOT%\tests\xsim
set GLBL=C:\2026.1\Vivado\data\verilog\src\glbl.v
cd /d "%XSIMDIR%"
echo GO-H4-SIMFULL0-00 PROGRAM=NO cwd=%CD%
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
  "%ROOT%\rtl\native_graph\topk\a7ng_topk_wavefront_minheap.sv" ^
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
  "%XSIMDIR%\tb_go_h4_simfull0_00.sv" > "%BAG%xvlog.txt" 2>&1
if errorlevel 1 (type "%BAG%xvlog.txt" & exit /b 2)
call xvlog.bat "%GLBL%" >> "%BAG%xvlog.txt" 2>&1
echo === xelab ===
call xelab.bat tb_go_h4_simfull0_00 glbl -s tb_go_h4_simfull0_00_sim -L xpm -timescale 1ns/1ps > "%BAG%xelab.txt" 2>&1
if errorlevel 1 (type "%BAG%xelab.txt" & exit /b 3)
echo === xsim ===
call xsim.bat tb_go_h4_simfull0_00_sim -runall > "%BAG%xsim.log" 2>&1
set XC=%ERRORLEVEL%
type "%BAG%xsim.log"
findstr /C:"GO_H4_SIMFULL0_00_DONE" /C:"H4_PRED=" "%BAG%xsim.log"
echo GO_H4_SIMFULL0_00_XSIM_EXIT=%XC% PROGRAM=NO
exit /b %XC%
