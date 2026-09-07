set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
file copy -force [file join $root tests/xsim/a7lm06_wmem.hex] [file join $work a7lm06_wmem.hex]
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set incm [file join $root rtl/native_graph/memory]
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
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
  [file join $bag tb_u8_r0.sv] \
]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv {*}$src -i $incq -i $incc -i $incm -i $bag > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U8_R0_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u8_r0 -s u8r0 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U8_R0_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u8r0 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U8_R0_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U8_R0_LM06_ACTIVE_CHAIN_ON_FROZEN_C9_PASS* $body]} {
  puts U8_R0_NOT_PASS
  exit 5
}
puts U8_R0_XSIM_OK
exit 0
