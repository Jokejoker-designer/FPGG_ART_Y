# run_a7ng_wf_global_topk_integrated.tcl — wf_global_topk_integrated_00
# Integrated a7ng_ddr_wavefront_top + global accumulator on Digilent AXI MIG.
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH WF-GLOBAL-TOPK-00 integrated]
set migroot [file join $root vivado ip mig_7series_0 mig_7series_0]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}

set prj [file join $outdir wf_global_topk_integrated_xsim.prj]
set fh [open $prj w]
puts $fh "# wf_global_topk_integrated_00 — ddr_wavefront_top + global Top-K"

foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/scorer/a7ng_scorer_lane.sv
  rtl/native_graph/scorer/a7ng_scorer_array.sv
  rtl/native_graph/scorer/a7ng_termgen_lane.sv
  rtl/native_graph/scorer/a7ng_termgen_array.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
  rtl/native_graph/memory/a7ng_ddr_feed_pp.sv
  rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv
  rtl/native_graph/memory/a7ng_cue_wave_stage.sv
  rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv
  rtl/ddr/mig_native_wrap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_wf_global_topk_integrated.sv]\""

foreach f [lsort [glob -nocomplain [file join $migroot user_design rtl *.v]]] {
  set bn [file tail $f]
  if {$bn eq "mig_7series_0_mig.v" || $bn eq "mig_7series_0_mig_sim.v"} { continue }
  puts $fh "verilog work \"$f\""
}
foreach d {axi clocking controller ecc ip_top phy ui} {
  foreach f [lsort [glob -nocomplain [file join $migroot user_design rtl $d *.v]]] {
    puts $fh "verilog work \"$f\""
  }
}
puts $fh "verilog work \"[file join $migroot user_design rtl mig_7series_0_mig_sim.v]\""
puts $fh "verilog work \"[file join $migroot example_design sim wiredly.v]\""
puts $fh "sv work \"[file join $migroot example_design sim ddr3_model.sv]\" -d x2Gb -d sg15E -d x16"
puts $fh "verilog work \"C:/2026.1/Vivado/data/verilog/src/glbl.v\""
close $fh
puts "WROTE $prj"

set incdir [file join $migroot example_design sim]
set xvlog_log [file join $outdir xvlog_wf_global_topk_integrated.log]
if {[catch {exec $xvlog_bin -prj $prj -i $incdir > $xvlog_log 2>@1} vlog_rc]} {
  puts "xvlog_rc=$vlog_rc"
  puts [read [open $xvlog_log r]]
  exit 2
}
puts [read [open $xvlog_log r]]

set xelab_log [file join $outdir xelab_wf_global_topk_integrated.log]
if {[catch {exec $xelab_bin -mt off -O0 tb_a7ng_wf_global_topk_integrated glbl \
    -s tb_a7ng_wf_global_topk_integrated_sim -L unisims_ver -L unimacro_ver -L secureip \
    -timescale 1ps/1ps > $xelab_log 2>@1} elab_rc]} {
  puts "xelab_rc=$elab_rc"
  puts [read [open $xelab_log r]]
  exit 3
}
puts [read [open $xelab_log r]]

set log [file join $outdir xsim_wf_global_topk_integrated.log]
if {[catch {exec $xsim_bin tb_a7ng_wf_global_topk_integrated_sim -runall > $log 2>@1} sim_rc]} {
  puts "xsim_rc=$sim_rc"
}
set sim_out [read [open $log r]]
puts $sim_out

if {[string match "*A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS*" $sim_out]} {
  puts A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_OK
  exit 0
}
puts A7NG_WF_GLOBAL_TOPK_INTEGRATED_NO_PASS
exit 5
