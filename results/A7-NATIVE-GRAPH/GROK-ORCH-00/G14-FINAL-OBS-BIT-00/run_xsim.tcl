set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
cd $bag
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $bag tb_a7ng_c12_host_obs.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag c12_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag c12_xvlog.log] r]]
  puts UNIT_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_c12_host_obs -s c12obs -timescale 1ns/1ps > [file join $bag c12_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag c12_xelab.log] r]]
  puts UNIT_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim c12obs -runall > [file join $bag c12_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag c12_xsim.log] r]]
}
set out [read [open [file join $bag c12_xsim.log] r]]
puts $out
if {![string match "*C12_HOST_OBS_XSIM_PASS*" $out]} { puts UNIT_XSIM_FAIL; exit 5 }
puts C12_HOST_OBS_XSIM_RAN
exit 0
