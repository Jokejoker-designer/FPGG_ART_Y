# P2-GATE14-C9-SOA-LM-BIT-04. PROGRAM=NO. Frozen ORACLE 653/689/237/60.
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
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_soa_lm_xsim.sv] \
  [file join $bag tb_a7ng_gate14_c9_soa_lm.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag unit_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xvlog.log] r]]
  puts UNIT_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_gate14_c9_soa_lm -s c9soa04 -timescale 1ns/1ps > [file join $bag unit_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xelab.log] r]]
  puts UNIT_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim c9soa04 -runall > [file join $bag unit_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xsim.log] r]]
}
set out [read [open [file join $bag unit_xsim.log] r]]
puts $out
if {![string match "*GATE14_C9_SOA_LM_XSIM_PASS*" $out]} {
  puts UNIT_XSIM_FAIL
  exit 5
}
puts C9SOA04_XSIM_PASS
exit 0
