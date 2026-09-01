# Dual-clock persist CDC unit. PROGRAM=NO.
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
  [file join [pwd] tb_a7ng_persist_axi_cdc.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag cdc_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xvlog.log] r]]
  puts CDC_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_persist_axi_cdc -s pcdc -timescale 1ns/1ps > [file join $bag cdc_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xelab.log] r]]
  puts CDC_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim pcdc -runall > [file join $bag cdc_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xsim.log] r]]
}
set out [read [open [file join $bag cdc_xsim.log] r]]
puts $out
if {![string match "*PERSIST_AXI_CDC_XSIM_PASS*" $out]} {
  puts CDC_XSIM_FAIL
  exit 5
}
puts CDC_UNIT_PASS
exit 0
