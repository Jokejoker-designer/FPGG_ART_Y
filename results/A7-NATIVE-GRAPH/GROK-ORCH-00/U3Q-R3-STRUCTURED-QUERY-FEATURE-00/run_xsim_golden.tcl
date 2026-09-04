# U3Q-R3 RTL vs frozen golden, every PREREG vector. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_golden]
file mkdir $work
cd $work
set pkg [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set rtl [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv]
set tb  [file join $bag tb_u3qr3_rtl_golden.sv]
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set incb $bag
set xvlog_log [file join $bag xvlog_golden.log]
if {[catch {exec $xvlog_bin -sv $pkg $rtl $tb -i $incq -i $incc -i $incb > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U3QR3_GOLDEN_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab_golden.log]
if {[catch {exec $xelab_bin tb_u3qr3_rtl_golden -s u3qr3g -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U3QR3_GOLDEN_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim_golden.log]
catch {exec $xsim_bin u3qr3g -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U3QR3_GOLDEN_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U3Q_R3_RTL_GOLDEN_PASS* $body]} {
  puts U3QR3_GOLDEN_NOT_PASS
  exit 5
}
puts U3QR3_GOLDEN_OK
exit 0
