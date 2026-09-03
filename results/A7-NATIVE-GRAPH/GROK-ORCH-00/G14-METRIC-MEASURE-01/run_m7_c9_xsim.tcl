# G14-METRIC-MEASURE-01 M7 C9 persist/AXI. NO RTL EDIT. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_g1g5_cofit.sv] \
  [file join $bag tb_g14_metric_m7_c9_xsim.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag m7c9_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag m7c9_xvlog.log] r]]
  puts M7C9_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_g14_metric_m7_c9_xsim -s g14m01c9 -timescale 1ns/1ps > [file join $bag m7c9_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag m7c9_xelab.log] r]]
  puts M7C9_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim g14m01c9 -runall > [file join $bag m7c9_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag m7c9_xsim.log] r]]
}
set out [read [open [file join $bag m7c9_xsim.log] r]]
puts $out
if {![string match "*G14_METRIC_M7_C9_XSIM_PASS*" $out]} {
  puts M7C9_XSIM_FAIL
  exit 5
}
puts M7C9_XSIM_OK
exit 0
