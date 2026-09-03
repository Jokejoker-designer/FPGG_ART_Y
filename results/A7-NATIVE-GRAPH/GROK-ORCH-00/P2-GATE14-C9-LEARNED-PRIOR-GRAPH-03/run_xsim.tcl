# P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03 XSim. PROGRAM=NO. No COM12.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
set xdir  [file join $bag xsim.dir]
file mkdir $bag
cd $bag
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $bag tb_a7ng_learned_prior_graph.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag unit_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xvlog.log] r]]
  puts UNIT_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_learned_prior_graph -s c9lp03 -timescale 1ns/1ps > [file join $bag unit_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xelab.log] r]]
  puts UNIT_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim c9lp03 -runall > [file join $bag unit_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xsim.log] r]]
}
set out [read [open [file join $bag unit_xsim.log] r]]
puts $out
if {![string match "*C9_LEARNED_PRIOR_GRAPH_XSIM_PASS*" $out]} {
  puts UNIT_XSIM_FAIL
  exit 5
}
puts C9LP03_XSIM_PASS
exit 0
