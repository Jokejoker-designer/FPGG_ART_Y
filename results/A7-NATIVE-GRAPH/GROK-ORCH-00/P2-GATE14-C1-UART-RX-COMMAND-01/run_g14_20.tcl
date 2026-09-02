# P2-GATE14-C1-UART-RX-COMMAND-01 D ladder. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set inc "-i [file join $root rtl/native_graph/control]"
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_gen_fast.sv] \
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_teacher_off_glue.sv] \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_teacher_off_soc_xsim.sv] \
  [file join $root rtl/board/a7ng_uart_rx100.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_uart_cmd_rx.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cmd_map.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cframe_tx.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cframe_sched.sv] \
  [file join [pwd] tb_a7ng_gate14_20_uart.sv] \
]
set vlog [file join $bag GATE14_20_UART_xvlog.log]
set elab [file join $bag GATE14_20_UART_xelab.log]
set simf [file join $bag GATE14_20_UART_XSIM.log]
if {[catch {exec $xvlog -sv {*}$inc {*}$src > $vlog 2>@1}]} {
  puts [read [open $vlog r]]; puts GATE14_20_XVLOG_FAIL; exit 2
}
if {[catch {exec $xelab tb_a7ng_gate14_20_uart -s g14_20 -timescale 1ns/1ps > $elab 2>@1}]} {
  puts [read [open $elab r]]; puts GATE14_20_XELAB_FAIL; exit 3
}
if {[catch {exec $xsim g14_20 -runall > $simf 2>@1}]} {
  puts [read [open $simf r]]
}
set out [read [open $simf r]]
puts $out
if {![string match "*GATE14_20_UART_XSIM_PASS*" $out]} {
  puts GATE14_20_XSIM_FAIL
  exit 5
}
puts GATE14_20_UART_XSIM_OK
exit 0
