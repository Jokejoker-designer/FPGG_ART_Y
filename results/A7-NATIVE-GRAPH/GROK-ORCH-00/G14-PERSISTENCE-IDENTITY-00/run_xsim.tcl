# G14-PERSISTENCE-IDENTITY-00 XSim. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd $bag
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

proc run_one {top snap srcs marker} {
  global xvlog xelab xsim bag
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

set store_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $bag tb_a7ng_persist_identity_store.sv] \
]
set graph_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $bag tb_a7ng_persist_identity_c9.sv] \
]

set rc [run_one tb_a7ng_persist_identity_store persist_id_store $store_src "PERSIST_IDENTITY_STORE_XSIM_PASS"]
if {$rc != 0} { exit $rc }
set rc [run_one tb_a7ng_persist_identity_c9 persist_id_c9 $graph_src "PERSIST_IDENTITY_C9_XSIM_PASS"]
if {$rc != 0} { exit $rc }
puts PERSIST_IDENTITY_XSIM_RAN
exit 0
