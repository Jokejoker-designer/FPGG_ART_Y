set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}
set src [list \
    [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root rtl/native_graph/share a7ng_multi_agent_share.sv] \
    [file join $root rtl/native_graph/frontier a7ng_frontier_buckets.sv] \
    [file join $root rtl/native_graph/topk a7ng_topk.sv] \
    [file join $root rtl/native_graph/perfmon a7ng_perfmon.sv] \
    [file join $xsimdir tb_a7ng_perfmon.sv]]
if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec $xelab_bin tb_a7ng_perfmon -s tb_a7ng_perfmon -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec $xsim_bin tb_a7ng_perfmon -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG_PERFMON_XSIM_PASS*" $sim_out]} { puts A7NG_PERFMON_NO_PASS; exit 5 }
puts A7NG_PERFMON_XSIM_OK
