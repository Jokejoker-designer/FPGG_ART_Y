# PERSIST-IDENTITY-SCHEMA-V2-00 XSim. PROGRAM=NO.
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
set rtl [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv]
set tb  [file join $bag tb_persist_identity_schema_v2.sv]
set incp [file join $root rtl/native_graph/pkg]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv $pkg $rtl $tb -i $incp > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts SCHEMA_V2_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_persist_identity_schema_v2 -s persistv2 -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts SCHEMA_V2_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin persistv2 -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[file exists persist_identity.csv]} {
  file copy -force persist_identity.csv [file join $bag persist_identity.csv]
}
if {[string match *PERSIST_IDENTITY_SCHEMA_V2_PASS* $body]} {
  puts SCHEMA_V2_XSIM_PASS
  exit 0
}
if {[string match *PERSIST_IDENTITY_SCHEMA_V2_FAIL* $body]} {
  puts SCHEMA_V2_XSIM_FAIL
  exit 7
}
puts SCHEMA_V2_XSIM_NO_MARKER
exit 5
