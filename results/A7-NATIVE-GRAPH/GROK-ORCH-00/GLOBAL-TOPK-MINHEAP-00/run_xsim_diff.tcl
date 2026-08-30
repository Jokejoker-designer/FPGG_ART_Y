set root [file normalize [file join [file dirname [info script]] ../../../..]]
set bag  [file normalize [file dirname [info script]]]
set xsimdir [file join $root tests xsim]
file mkdir $bag
cd $xsimdir
set xvlog_bin {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab_bin {C:/2026.1/Vivado/bin/xelab.bat}
set xsim_bin  {C:/2026.1/Vivado/bin/xsim.bat}
set prj [file join $bag minheap_diff.prj]
set fh [open $prj w]
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_topk_minheap_diff.sv]\""
close $fh
if {[catch {exec $xvlog_bin -sv -prj $prj > [file join $bag xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag xvlog.log] r]]
  exit 2
}
if {[catch {exec $xelab_bin tb_a7ng_topk_minheap_diff -s minheap_diff_sim -timescale 1ns/1ps > [file join $bag xelab.log] 2>@1}]} {
  puts [read [open [file join $bag xelab.log] r]]
  exit 3
}
if {[catch {exec $xsim_bin minheap_diff_sim -runall > [file join $bag xsim.log] 2>@1}]} {
  puts [read [open [file join $bag xsim.log] r]]
}
set out [read [open [file join $bag xsim.log] r]]
puts $out
if {[string match "*GLOBAL_TOPK_MINHEAP_XSIM_PASS*" $out]} { exit 0 }
exit 5
