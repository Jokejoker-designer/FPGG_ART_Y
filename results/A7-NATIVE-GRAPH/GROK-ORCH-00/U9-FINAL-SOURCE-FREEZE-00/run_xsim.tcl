# U9-FINAL-SOURCE-FREEZE-00 — production-path confirm only.
# Re-runs U8R TB against frozen rtl/. Not U9R suite. Not U9S. BIT=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_g1g5_cofit.sv] \
  [file join $bag tb_u8r_remove_synthetic.sv] \
]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv {*}$src > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U9_FREEZE_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u8r_remove_synthetic -s u9freeze -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U9_FREEZE_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u9freeze -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U9_FREEZE_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS* $body]} {
  puts U9_FREEZE_U8R_NOT_PASS
  exit 5
}
puts U9_FINAL_SOURCE_FREEZE_XSIM_OK
exit 0
