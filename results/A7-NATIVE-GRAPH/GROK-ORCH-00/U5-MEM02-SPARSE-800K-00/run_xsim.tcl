# U5 scale + sentinel. PROGRAM=NO. U6=CLOSED.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set u3q  [file normalize [file join $bag ../U3Q-R3-STRUCTURED-QUERY-FEATURE-00]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set pkg [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set qse [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv]
set mem [file join $root rtl/native_graph/memory/a7ng_axi_mem_model.sv]
set rtl [file join $root rtl/native_graph/memory/a7ng_sparse_dir_axi.sv]
set tb  [file join $bag tb_u5_mem02_sparse_800k.sv]
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $qse $mem $rtl $tb -i $incq -i $incc -i $u3q -i $bag > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts FIRST_DIVERGENCE
  puts U5_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u5_mem02_sparse_800k -s u5mem02 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts FIRST_DIVERGENCE
  puts U5_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u5mem02 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U5_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U5_MEM02_SPARSE_800K_PASS* $body]} {
  puts U5_NOT_PASS
  exit 5
}
puts U5_XSIM_OK
exit 0
