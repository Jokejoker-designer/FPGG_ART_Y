# LOCAL-SORT-ELIDE-00 SET equality. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xsimdir [file join $root tests xsim]
file mkdir $bag
cd $xsimdir
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set xvlog_bin {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab_bin {C:/2026.1/Vivado/bin/xelab.bat}
set xsim_bin  {C:/2026.1/Vivado/bin/xsim.bat}
set prj [file join $bag set.prj]
set fh [open $prj w]
puts $fh "sv work \"[file join $root rtl/native_graph/pkg/a7ng_pkg.sv]\""
puts $fh "sv work \"[file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv]\""
puts $fh "sv work \"[file join $bag tb_g14_local_set_diff.sv]\""
close $fh
if {[catch {exec $xvlog_bin -sv -prj $prj > [file join $bag set_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag set_xvlog.log] r]]
  puts SET_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab_bin tb_g14_local_set_diff -s g14lse -timescale 1ns/1ps > [file join $bag set_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag set_xelab.log] r]]
  puts SET_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim_bin g14lse -runall > [file join $bag set_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag set_xsim.log] r]]
}
set out [read [open [file join $bag set_xsim.log] r]]
puts $out
if {[string match "*LOCAL_SORT_ELIDE_SET_PASS*" $out]} { puts SET_OK; exit 0 }
puts SET_FAIL
exit 5
