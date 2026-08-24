# NG-02R-FLOW: Top-8→frontier backpressure / conservation XSim
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set outdir [file join $root results/A7-NATIVE-GRAPH/NG-02R-FLOW]
file mkdir $outdir

set src [list \
    [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root rtl/native_graph/topk a7ng_topk.sv] \
    [file join $root rtl/native_graph/topk a7ng_ng02_core.sv] \
    [file join $root rtl/native_graph/frontier a7ng_frontier_buckets.sv] \
    [file join $xsimdir tb_a7ng_ng02_flow.sv]]

if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts XVLOG_FAIL
  exit 2
}
puts $vlog_out

if {[catch {exec xelab tb_a7ng_ng02_flow -s tb_a7ng_ng02_flow -timescale 1ns/1ps} elab_out]} {
  puts $elab_out
  puts XELAB_FAIL
  exit 3
}
puts $elab_out

if {[catch {exec xsim tb_a7ng_ng02_flow -runall} sim_out]} {
  puts $sim_out
  puts XSIM_FAIL
  exit 4
}
puts $sim_out

set logfile [file join $outdir xsim_flow.log]
set fd [open $logfile w]
puts $fd $vlog_out
puts $fd $elab_out
puts $fd $sim_out
close $fd

if {![string match "*A7NG02R_FLOW_XSIM_PASS*" $sim_out]} {
  puts A7NG02R_FLOW_XSIM_NO_PASS
  exit 5
}
puts A7NG02R_FLOW_XSIM_OK
