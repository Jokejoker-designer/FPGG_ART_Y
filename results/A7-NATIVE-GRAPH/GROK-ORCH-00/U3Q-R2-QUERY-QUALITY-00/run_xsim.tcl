# U3Q-R2 held-out spot XSim vs FPGA extractor. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

set work [file join $bag xsim_work]
file mkdir $work
cd $work

set rtl [file join $root rtl/native_graph/query/a7ng_query_feature_extract.sv]
set tb  [file join $bag tb_u3q_r2_spot.sv]
set inc [file join $root rtl/native_graph/control]

set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $rtl $tb -i $inc > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U3QR2_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u3q_r2_spot -s u3qr2_spot -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U3QR2_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
if {[catch {exec $xsim_bin u3qr2_spot -R -log $xsim_log} rc]} {
  puts "xsim_rc=$rc"
}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U3Q_R2_XSIM_SPOT_PASS* $body]} {
  puts U3QR2_NOT_PASS
  exit 5
}
puts U3QR2_XSIM_OK
exit 0
