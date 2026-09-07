# U4A-R6 protocol: valid=1,key=0 probes; valid=0,key=0 does not. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_protocol]
file mkdir $work
cd $work
set rtl [file join $root rtl/native_graph/query/a7ng_route_valid_gate.sv]
set tb  [file join $bag tb_u4ar6_valid_key0.sv]
set xvlog_log [file join $bag xvlog_protocol.log]
if {[catch {exec $xvlog_bin -sv $rtl $tb > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U4AR6_PROTOCOL_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab_protocol.log]
if {[catch {exec $xelab_bin tb_u4ar6_valid_key0 -s u4ar6p -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U4AR6_PROTOCOL_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim_protocol.log]
catch {exec $xsim_bin u4ar6p -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U4AR6_PROTOCOL_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U4A_R6_PROTOCOL_PASS* $body]} {
  puts U4AR6_PROTOCOL_NOT_PASS
  exit 5
}
puts U4AR6_PROTOCOL_OK
exit 0
