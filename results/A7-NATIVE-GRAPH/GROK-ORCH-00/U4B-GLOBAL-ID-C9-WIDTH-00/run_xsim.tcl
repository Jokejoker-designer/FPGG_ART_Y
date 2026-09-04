# U4B pack unit XSim. Does not edit C9 glue (U2R fileset). PROGRAM=NO.
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
set rtl [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv]
set tb  [file join $bag tb_a7ng_id20_pack.sv]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $rtl $tb > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U4B_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_a7ng_id20_pack -s u4b_pack -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U4B_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u4b_pack -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U4B_ID20_PACK_PASS* $body]} { puts U4B_NOT_PASS; exit 5 }
puts U4B_PACK_XSIM_OK
exit 0
