# collision XSim. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv] \
  [file join [pwd] tb_a7ng_persist_axi_mem.sv] \
  [file join [pwd] tb_a7ng_persist_axi_collision.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag coll_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag coll_xvlog.log] r]]
  puts COLL_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_persist_axi_collision -s pcoll -timescale 1ns/1ps > [file join $bag coll_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag coll_xelab.log] r]]
  puts COLL_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim pcoll -runall > [file join $bag coll_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag coll_xsim.log] r]]
}
set out [read [open [file join $bag coll_xsim.log] r]]
puts $out
if {![string match "*PERSIST_AXI_COLLISION_XSIM_PASS*" $out]} {
  puts COLL_XSIM_FAIL
  exit 5
}
puts COLL_UNIT_PASS
exit 0
