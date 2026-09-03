# P2-GATE14-C9-CMD-ACCEPT-FIX-05 graph-only. PROGRAM=NO.
# Default: hold-until-handshake do_cmd. Pass +BROKEN_HS via run_graph_broken.tcl.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd $bag
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $bag a7ng_gate14_c9_graph_only_xsim.sv] \
  [file join $bag tb_a7ng_gate14_c9_cmd_accept.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag graph_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag graph_xvlog.log] r]]
  puts GRAPH_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_gate14_c9_cmd_accept -s c9cmd05 -timescale 1ns/1ps > [file join $bag graph_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag graph_xelab.log] r]]
  puts GRAPH_XELAB_FAIL
  exit 3
}
set plus [list]
if {[info exists ::env(C9_BROKEN_HS)] && $::env(C9_BROKEN_HS) eq "1"} {
  set plus [list -testplusarg BROKEN_HS]
  puts "PLUSARG BROKEN_HS"
}
if {[catch {exec $xsim c9cmd05 -runall {*}$plus > [file join $bag graph_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag graph_xsim.log] r]]
}
set out [read [open [file join $bag graph_xsim.log] r]]
puts $out
if {![string match "*GATE14_C9_CMD_ACCEPT_GRAPH_PASS*" $out]} {
  puts GRAPH_XSIM_FAIL
  exit 5
}
puts C9CMD05_GRAPH_PASS
exit 0
