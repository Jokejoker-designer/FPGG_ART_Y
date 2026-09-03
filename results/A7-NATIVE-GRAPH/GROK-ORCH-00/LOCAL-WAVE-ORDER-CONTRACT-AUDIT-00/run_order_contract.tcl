# LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00. PROGRAM=NO. RTL_EDIT=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xsimdir [file join $root tests xsim]
file mkdir $bag
cd $xsimdir
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set xvlog_bin {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab_bin {C:/2026.1/Vivado/bin/xelab.bat}
set xsim_bin  {C:/2026.1/Vivado/bin/xsim.bat}
set prj [file join $bag order.prj]
set fh [open $prj w]
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $bag tb_g14_wave_order_contract.sv]\""
close $fh
if {[catch {exec $xvlog_bin -sv -prj $prj > [file join $bag order_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag order_xvlog.log] r]]
  puts ORDER_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab_bin tb_g14_wave_order_contract -s g14woc -timescale 1ns/1ps > [file join $bag order_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag order_xelab.log] r]]
  puts ORDER_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim_bin g14woc -runall > [file join $bag order_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag order_xsim.log] r]]
}
set out [read [open [file join $bag order_xsim.log] r]]
puts $out
if {[string match "*LOCAL_WAVE_ORDER_CONTRACT_PASS*" $out]} { puts ORDER_CONTRACT_OK; exit 0 }
puts ORDER_CONTRACT_FAIL
exit 5
