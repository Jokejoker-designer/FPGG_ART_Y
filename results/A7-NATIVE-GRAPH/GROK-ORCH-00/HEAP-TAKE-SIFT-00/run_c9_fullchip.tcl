# TOPK-SORT-BOUND-00 frozen C9/OUT regression. Same DUT/TB as BIT-07. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set bit07 [file join $root results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-SOC-IO-SAFE-BIT-07]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

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
  [file join $bit07 tb_a7ng_gate14_c9_soc_cofit.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag c9_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag c9_xvlog.log] r]]
  puts C9_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_gate14_c9_soc_cofit -s g14sbc9 -timescale 1ns/1ps > [file join $bag c9_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag c9_xelab.log] r]]
  puts C9_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim g14sbc9 -runall > [file join $bag c9_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag c9_xsim.log] r]]
}
set out [read [open [file join $bag c9_xsim.log] r]]
puts $out
if {![string match "*GATE14_C9_SOC_COFIT_XSIM_PASS*" $out]} {
  puts C9_XSIM_FAIL
  exit 5
}
if {![string match "*8382238122802120*" $out]} {
  puts C9_PACK_HOLD_A_MISSING
  exit 6
}
if {![string match "*LM_OUT_A/U/C/B=653/689/237/60*" $out]} {
  puts C9_OUT_MISMATCH
  exit 7
}
puts C9_FROZEN_REGRESSION_PASS
exit 0
