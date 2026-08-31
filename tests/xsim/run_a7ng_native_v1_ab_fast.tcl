set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set snapdir [file join $xsimdir xsim.dir.board_lane_fast]
file mkdir $snapdir
cd $xsimdir

set src [list \
  [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/scorer a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/scorer a7ng_scorer_array.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_lane.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_lane_fold6.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_array_fold6.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk_wavefront_global.sv] \
  [file join $root rtl/native_graph/topk a7ng_topk_wavefront_minheap.sv] \
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

if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts "XVLOG_FAIL"
  exit 2
}
puts $vlog_out

if {[catch {exec xelab tb_a7ng_native_v1_ab_fast -s tb_a7ng_native_v1_ab_fast_sim -timescale 1ns/1ps} elab_out]} {
  puts $elab_out
  puts "XELAB_FAIL"
  exit 3
}
puts $elab_out

set logfile [file join $root results A7-NATIVE-GRAPH A-FAST-LM-BOARD-LANE-00 xsim_fast.log]
if {[catch {exec xsim tb_a7ng_native_v1_ab_fast_sim -runall} sim_out]} {
  set f [open $logfile w]
  puts $f $sim_out
  close $f
  puts $sim_out
  puts "XSIM_FAIL"
  exit 4
}
set f [open $logfile w]
puts $f $sim_out
close $f
puts $sim_out

if {![string match "*A_FAST_LM_BOARD_LANE_XSIM_PASS*" $sim_out]} {
  puts "A_FAST_LM_BOARD_LANE_NO_PASS"
  exit 5
}
puts "A_FAST_LM_BOARD_LANE_OK"
