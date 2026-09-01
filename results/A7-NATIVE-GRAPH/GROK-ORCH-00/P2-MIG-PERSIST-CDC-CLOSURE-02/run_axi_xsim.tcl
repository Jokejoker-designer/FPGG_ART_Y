# P2-G1G5-FULLCHIP-MIG-PERSIST-01 AXI unit XSim. PROGRAM=NO.
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
  [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv] \
  [file join [pwd] tb_a7ng_persist_axi_mem.sv] \
  [file join [pwd] tb_a7ng_persist_axi_bridge.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag axi_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag axi_xvlog.log] r]]
  puts AXI_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_persist_axi_bridge -s paxi -timescale 1ns/1ps > [file join $bag axi_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag axi_xelab.log] r]]
  puts AXI_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim paxi -runall > [file join $bag axi_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag axi_xsim.log] r]]
}
set out [read [open [file join $bag axi_xsim.log] r]]
puts $out
if {![string match "*PERSIST_AXI_MIG_XSIM_PASS*" $out]} {
  puts AXI_XSIM_FAIL
  exit 5
}
puts AXI_UNIT_PASS
exit 0
