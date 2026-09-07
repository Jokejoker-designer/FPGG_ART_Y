set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set incm [file join $root rtl/native_graph/memory]
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_materialize.sv] \
  [file join $root rtl/native_graph/lm/a7ng_lm_ctx_encoder_v1.sv] \
  [file join $bag tb_u8_r2.sv] \
]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv {*}$src -i $incm -i $bag > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U8_R2_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u8_r2 -s u8r2 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U8_R2_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u8r2 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {![string match *U8_R2_LM_CONTEXT_ENCODER_V1_PASS* $body]} {
  puts U8_R2_NOT_PASS
  exit 5
}
puts U8_R2_XSIM_OK
exit 0
