# G14-TEACHER-OFF-NATIVE-CAUSALITY-00 Gate T XSim. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

proc run_one {cwd top snap srcs marker} {
  global xvlog xelab xsim bag
  cd $cwd
  set xvlog_log [file join $bag ${snap}_xvlog.log]
  set xelab_log [file join $bag ${snap}_xelab.log]
  set xsim_log  [file join $bag ${snap}_xsim.log]
  if {[catch {exec $xvlog -sv {*}$srcs > $xvlog_log 2>@1}]} {
    puts [read [open $xvlog_log r]]
    puts "${snap}_XVLOG_FAIL"
    return 2
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > $xelab_log 2>@1}]} {
    puts [read [open $xelab_log r]]
    puts "${snap}_XELAB_FAIL"
    return 3
  }
  if {[catch {exec $xsim $snap -runall > $xsim_log 2>@1}]} {
    puts [read [open $xsim_log r]]
  }
  set out [read [open $xsim_log r]]
  puts $out
  if {($marker ne "") && ![string match "*${marker}*" $out]} {
    puts "${snap}_XSIM_FAIL"
    return 5
  }
  return 0
}

set graph_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $bag tb_a7ng_teacher_off_graph.sv] \
]
set soc_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_g1g5_cofit.sv] \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_soc_cofit_xsim.sv] \
  [file join $bag tb_a7ng_teacher_off_soc.sv] \
]

set rc [run_one $bag tb_a7ng_teacher_off_graph toff_g $graph_src "TEACHER_OFF_GRAPH_XSIM_PASS"]
if {$rc != 0} { exit $rc }
set rc [run_one [file join $root tests xsim] tb_a7ng_teacher_off_soc toff_s $soc_src "TEACHER_OFF_SOC_XSIM_PASS"]
if {$rc != 0} { exit $rc }
puts TEACHER_OFF_XSIM_RAN
exit 0
