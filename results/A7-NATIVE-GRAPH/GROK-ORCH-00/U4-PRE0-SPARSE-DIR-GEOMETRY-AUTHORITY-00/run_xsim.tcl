# U4-PRE0 P4_4k_h64 geometry. PROGRAM=NO. U4-MEM02 STOPPED.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set r2   [file normalize [file join $bag ../U4-R2-DDR-SPARSE-DIRECTORY-00]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

# ---- 10. existing AXI protocol tests still pass ----
set r2_work [file join $r2 xsim_work]
file mkdir $r2_work
cd $r2_work
set pkg [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set mem [file join $root rtl/native_graph/memory/a7ng_axi_mem_model.sv]
set rtl [file join $root rtl/native_graph/memory/a7ng_sparse_dir_axi.sv]
set tb_r2 [file join $r2 tb_a7ng_sparse_dir_axi.sv]
set xvlog_r2 [file join $bag xvlog_u4r2.log]
if {[catch {exec $xvlog_bin -sv $pkg $mem $rtl $tb_r2 > $xvlog_r2 2>@1}]} {
  puts [read [open $xvlog_r2 r]]
  puts FIRST_DIVERGENCE
  puts U4R2_PROTOCOL_XVLOG_FAIL
  exit 2
}
set xelab_r2 [file join $bag xelab_u4r2.log]
if {[catch {exec $xelab_bin tb_a7ng_sparse_dir_axi -s u4r2_dir -timescale 1ns/1ps > $xelab_r2 2>@1}]} {
  puts [read [open $xelab_r2 r]]
  puts FIRST_DIVERGENCE
  puts U4R2_PROTOCOL_XELAB_FAIL
  exit 3
}
set xsim_r2 [file join $bag xsim_u4r2.log]
catch {exec $xsim_bin u4r2_dir -R -log $xsim_r2}
set body_r2 [read [open $xsim_r2 r]]
puts $body_r2
if {![string match *U4_R2_DDR_SPARSE_DIRECTORY_PASS* $body_r2]} {
  puts FIRST_DIVERGENCE
  puts U4R2_PROTOCOL_REGRESS
  exit 5
}
puts U4R2_PROTOCOL_STILL_PASS

# ---- PRE0 geometry ----
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set tb [file join $bag tb_u4pre0_sparse_dir_geometry.sv]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $mem $rtl $tb -i $bag > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts FIRST_DIVERGENCE
  puts U4PRE0_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u4pre0_sparse_dir_geometry -s u4pre0g -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts FIRST_DIVERGENCE
  puts U4PRE0_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u4pre0g -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U4PRE0_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U4_PRE0_SPARSE_DIR_GEOMETRY_PASS* $body]} {
  puts U4PRE0_NOT_PASS
  exit 5
}
puts U4PRE0_XSIM_OK
exit 0
