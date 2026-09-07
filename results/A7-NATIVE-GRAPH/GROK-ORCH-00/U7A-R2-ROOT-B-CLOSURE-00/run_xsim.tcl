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
set st  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv]
set g1  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv]
set tb  [file join $bag tb_u7a_r2.sv]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $st $g1 $tb > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U7A_R2_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u7a_r2 -s u7ar2 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U7A_R2_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u7ar2 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U7A_R2_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U7A_R2_ROOTB_CLOSURE_PASS* $body]} {
  puts U7A_R2_NOT_PASS
  exit 5
}
puts U7A_R2_XSIM_OK
exit 0
