# TOPK-SORT-BOUND-00: local stream minheap vs frozen a7ng_topk. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xsimdir [file join $root tests xsim]
file mkdir $bag
cd $xsimdir
set xvlog_bin {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab_bin {C:/2026.1/Vivado/bin/xelab.bat}
set xsim_bin  {C:/2026.1/Vivado/bin/xsim.bat}
if {[catch {exec $xvlog_bin -sv \
    [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
    [file join $root rtl/native_graph/topk/a7ng_topk.sv] \
    [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
    [file join $xsimdir tb_a7ng_topk_stream_minheap_diff.sv] \
    > [file join $bag local_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag local_xvlog.log] r]]
  puts LOCAL_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab_bin tb_a7ng_topk_stream_minheap_diff -s g14sb_ldiff -timescale 1ns/1ps > [file join $bag local_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag local_xelab.log] r]]
  puts LOCAL_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim_bin g14sb_ldiff -runall > [file join $bag local_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag local_xsim.log] r]]
}
set out [read [open [file join $bag local_xsim.log] r]]
puts $out
if {[string match "*LOCAL_MINHEAP_STREAM_TOP8_XSIM_PASS*" $out]} { puts LOCAL_DIFF_OK; exit 0 }
puts LOCAL_DIFF_FAIL
exit 5
