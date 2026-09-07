# U4B scorer -> local TopK -> C9 20-bit. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work_heap]
file mkdir $work
cd $work
set files [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $bag tb_u4b_scorer_heap_c9.sv]]
set xvlog_log [file join $bag xvlog_heap.log]
if {[catch {exec $xvlog_bin -sv {*}$files > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U4B_HEAP_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab_heap.log]
if {[catch {exec $xelab_bin tb_u4b_scorer_heap_c9 -s u4b_heap -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U4B_HEAP_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim_heap.log]
catch {exec $xsim_bin u4b_heap -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U4B_SCORER_HEAP_C9_PASS* $body]} { puts U4B_HEAP_NOT_PASS; exit 5 }
puts U4B_HEAP_XSIM_OK
exit 0
