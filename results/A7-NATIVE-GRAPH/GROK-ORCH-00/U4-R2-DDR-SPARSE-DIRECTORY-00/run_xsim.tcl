# U4-R2 AXI sparse dir XSim. PROGRAM=NO. SOC=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

set work [file join $bag xsim_work]
file mkdir $work
cd $work

set pkg  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set mem  [file join $root rtl/native_graph/memory/a7ng_axi_mem_model.sv]
set rtl  [file join $root rtl/native_graph/memory/a7ng_sparse_dir_axi.sv]
set tb   [file join $bag tb_a7ng_sparse_dir_axi.sv]

# Refuse old BRAM toy in this compile.
set toy [file join $root rtl/native_graph/memory/a7ng_sparse_dir.sv]
set f [open $rtl r]
set body [read $f]
close $f
if {[string match "*head [0:1][0:15][0:7]*" $body]} {
  puts "REFUSE: hard-coded [2][16][8] geometry in AXI walker"
  exit 3
}

set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $mem $rtl $tb > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U4R2_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_a7ng_sparse_dir_axi -s u4r2_dir -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U4R2_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
if {[catch {exec $xsim_bin u4r2_dir -R -log $xsim_log} rc]} {
  puts "xsim_rc=$rc"
}
set out [read [open $xsim_log r]]
puts $out
if {![string match *U4_R2_DDR_SPARSE_DIRECTORY_PASS* $out]} {
  puts U4R2_NOT_PASS
  exit 5
}
puts U4R2_XSIM_OK
exit 0
