# U4B C9 glue + bind 20-bit path. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work_chain]
file mkdir $work
cd $work
set files [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $bag tb_u4b_c9_bind_width.sv]]
set xvlog_log [file join $bag xvlog_chain.log]
if {[catch {exec $xvlog_bin -sv {*}$files > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U4B_CHAIN_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab_chain.log]
if {[catch {exec $xelab_bin tb_u4b_c9_bind_width -s u4b_chain -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U4B_CHAIN_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim_chain.log]
catch {exec $xsim_bin u4b_chain -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U4B_C9_BIND_WIDTH_PASS* $body]} { puts U4B_CHAIN_NOT_PASS; exit 5 }
puts U4B_CHAIN_XSIM_OK
exit 0
