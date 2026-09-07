# U3Q-R3 XSim. PROGRAM=NO. SOC=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set pkg [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set rtl [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv]
set tb  [file join $bag tb_a7ng_query_struct_extract.sv]
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $rtl $tb -i $incq -i $incc > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U3QR3_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_a7ng_query_struct_extract -s u3qr3 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U3QR3_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u3qr3 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U3Q_R3_XSIM_PASS* $body]} { puts U3QR3_NOT_PASS; exit 5 }
puts U3QR3_XSIM_OK
exit 0
