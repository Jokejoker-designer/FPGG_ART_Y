# G14-PREBOARD-CLOSURE-00 full-chip SoC XSim on epoch law. PROGRAM=NO.
# Same DUT/TB as P2-GATE14-C9-SOC-IO-SAFE-BIT-07. Logs stay in this bag.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set bit07 [file join $root results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-SOC-IO-SAFE-BIT-07]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
# Hex $readmemh("a7lm06_wmem.hex") resolves from cwd. BIT-07 ran from tests/xsim.
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
if {[catch {exec $xvlog -sv {*}$src > [file join $bag fullchip_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag fullchip_xvlog.log] r]]
  puts FULLCHIP_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_gate14_c9_soc_cofit -s g14fc00 -timescale 1ns/1ps > [file join $bag fullchip_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag fullchip_xelab.log] r]]
  puts FULLCHIP_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim g14fc00 -runall > [file join $bag fullchip_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag fullchip_xsim.log] r]]
}
set out [read [open [file join $bag fullchip_xsim.log] r]]
puts $out
if {![string match "*GATE14_C9_SOC_COFIT_XSIM_PASS*" $out]} {
  puts FULLCHIP_XSIM_FAIL
  exit 5
}
puts G14_FULLCHIP_EPOCH_XSIM_PASS
exit 0
