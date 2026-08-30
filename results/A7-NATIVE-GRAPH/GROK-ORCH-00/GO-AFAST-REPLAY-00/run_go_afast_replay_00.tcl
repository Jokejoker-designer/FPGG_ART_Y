# GO-AFAST-REPLAY-00 — existence vehicle XSim on THIS grok-orch checkout
# Confirms two-pass core 355182A7 still prints A_FAST pred=664.
# cwd = tests/xsim so a7lm06_wmem.hex resolves. Logs in this bag.
# PROGRAM=NO. No SoC/MIG. No open_hw_manager.
set root D:/Jetking_sem4/SEM_4/arty-a7-online-lm-grok-orch-00
set xsimdir [file join $root tests xsim]
set outdir [file join $root results A7-NATIVE-GRAPH GROK-ORCH-00 GO-AFAST-REPLAY-00]
file mkdir $outdir
cd $xsimdir

set core_sv [file nativename [file join $root rtl lm tiny_gpt803k_core.sv]]
set core_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$core_sv' | Select-Object -ExpandProperty Hash"]]
puts "CORE_SHA256=$core_sha"
if {$core_sha ne "355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7"} {
  puts stderr "STOP: core SHA drifted $core_sha"
  exit 3
}

set src [list \
  [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/scorer a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/scorer a7ng_scorer_array.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_lane.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk_wavefront_global.sv] \
  [file join $root rtl/native_graph/topk a7ng_ng02_core.sv] \
  [file join $root rtl/native_graph/frontier a7ng_frontier_buckets.sv] \
  [file join $root rtl/native_graph/memory a7ng_ddr_soa_axi_bridge.sv] \
  [file join $root rtl/native_graph/memory a7ng_soa_plane_engine.sv] \
  [file join $root rtl/native_graph/memory a7ng_soa_plane_fetch.sv] \
  [file join $root rtl/native_graph/memory a7ng_axi_read_stream.sv] \
  [file join $root rtl/native_graph/memory a7ng_cue_soa_wavefront.sv] \
  [file join $root rtl/native_graph/memory a7ng_cue_soa_mig_top.sv] \
  [file join $root rtl/native_graph/integrate a7ng_lm_graph_arb.sv] \
  [file join $root rtl/native_graph/lm a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate a7ng_native_v1_ab_core.sv] \
  [file join $root rtl/lm a7lm06_pkg.sv] \
  [file join $root rtl/lm isqrt32.sv] \
  [file join $root rtl/lm floordiv_s48.sv] \
  [file join $root rtl/lm weight_bram803k.sv] \
  [file join $root rtl/lm weight_bram_tdp8.sv] \
  [file join $root rtl/lm weight_tile803k.sv] \
  [file join $root rtl/lm act_ram128k16.sv] \
  [file join $root rtl/lm snap_ram4k16.sv] \
  [file join $root rtl/lm tiny_gpt803k_core.sv] \
  [file join $xsimdir a7ng_axi_soa_mem_stub.sv] \
  [file join $xsimdir tb_a7ng_native_v1_ab_fast.sv]]

set xvlog_log [file join $outdir xvlog.txt]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  set f [open $xvlog_log w]; puts $f $vlog_out; close $f
  puts $vlog_out
  puts "XVLOG_FAIL"
  exit 2
}
set f [open $xvlog_log w]; puts $f $vlog_out; close $f
puts $vlog_out

set glbl C:/2026.1/Vivado/data/verilog/src/glbl.v
set used_glbl 0
if {[file exists $glbl]} {
  if {![catch {exec xvlog $glbl} glbl_out]} {
    set used_glbl 1
  }
}

set xelab_log [file join $outdir xelab.txt]
set elab_ok 0
if {$used_glbl} {
  if {![catch {exec xelab tb_a7ng_native_v1_ab_fast glbl -s tb_a7ng_native_v1_ab_fast_sim -L xpm -timescale 1ns/1ps} elab_out]} {
    set elab_ok 1
  }
}
if {!$elab_ok} {
  if {[catch {exec xelab tb_a7ng_native_v1_ab_fast -s tb_a7ng_native_v1_ab_fast_sim -L xpm -timescale 1ns/1ps} elab_out]} {
    set f [open $xelab_log w]; puts $f $elab_out; close $f
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
  }
}
set f [open $xelab_log w]; puts $f $elab_out; close $f
puts $elab_out

set logfile [file join $outdir xsim.log]
if {[catch {exec xsim tb_a7ng_native_v1_ab_fast_sim -runall} sim_out]} {
  set f [open $logfile w]; puts $f $sim_out; close $f
  puts $sim_out
  puts "XSIM_FAIL"
  exit 4
}
set f [open $logfile w]; puts $f $sim_out; close $f
puts $sim_out

if {![string match "*A_FAST_LM_BOARD_LANE_XSIM_PASS*" $sim_out]} {
  puts "A_FAST_LM_BOARD_LANE_NO_PASS"
  exit 5
}
if {![string match "*pred=664*" $sim_out]} {
  puts "A_FAST_LM_BOARD_LANE_NO_PRED664"
  exit 6
}
puts "GO_AFAST_REPLAY_00_OK pred=664 PROGRAM=NO EXISTENCE=not_claimed"
exit 0
