# P2-PERSIST-GEN-FAST-SERIAL-STATE-01 XSim. PROGRAM=NO.
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
  [file join $root rtl/native_graph/learn/a7ng_persist_gen_fast.sv] \
  [file join [pwd] tb_a7ng_persist_gen_fast.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag unit_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xvlog.log] r]]
  puts UNIT_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_persist_gen_fast -s g4s01 -timescale 1ns/1ps > [file join $bag unit_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xelab.log] r]]
  puts UNIT_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim g4s01 -runall > [file join $bag unit_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xsim.log] r]]
}
set out [read [open [file join $bag unit_xsim.log] r]]
puts $out
if {![string match "*PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS*" $out]} {
  puts UNIT_XSIM_FAIL
  exit 5
}
puts SERIAL_STATE_01_XSIM_PASS
exit 0
