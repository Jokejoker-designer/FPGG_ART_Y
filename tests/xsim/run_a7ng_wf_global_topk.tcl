# run_a7ng_wf_global_topk.tcl — wf_global_topk_00 XSim gate
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH WF-GLOBAL-TOPK-00]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}

set prj [file join $outdir wf_global_topk_xsim.prj]
set fh [open $prj w]
puts $fh "# wf_global_topk_00 — cross-wave global Top-8"
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_wf_global_topk.sv]\""
close $fh
puts "WROTE $prj"

set xvlog_log [file join $outdir xvlog_wf_global_topk.log]
if {[catch {exec $xvlog_bin -prj $prj > $xvlog_log 2>@1} vlog_rc]} {
  puts "xvlog_rc=$vlog_rc"
  puts [read [open $xvlog_log r]]
  exit 2
}
puts [read [open $xvlog_log r]]

set xelab_log [file join $outdir xelab_wf_global_topk.log]
if {[catch {exec $xelab_bin tb_a7ng_wf_global_topk -s tb_a7ng_wf_global_topk_sim \
    -timescale 1ns/1ps > $xelab_log 2>@1} elab_rc]} {
  puts "xelab_rc=$elab_rc"
  puts [read [open $xelab_log r]]
  exit 3
}
puts [read [open $xelab_log r]]

set log [file join $outdir xsim_wf_global_topk.log]
if {[catch {exec $xsim_bin tb_a7ng_wf_global_topk_sim -runall > $log 2>@1} sim_rc]} {
  puts "xsim_rc=$sim_rc"
}
set sim_out [read [open $log r]]
puts $sim_out

if {[string match "*A7NG_WF_GLOBAL_TOPK_XSIM_PASS*" $sim_out]} {
  puts A7NG_WF_GLOBAL_TOPK_XSIM_OK
  exit 0
}
puts A7NG_WF_GLOBAL_TOPK_NO_PASS
exit 5
