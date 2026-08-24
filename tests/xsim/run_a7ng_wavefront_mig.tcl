# run_a7ng_wavefront_mig.tcl — ddr_wavefront_00 bounded ping/pong wave on Digilent AXI MIG
# Official mig.prj unmodified (Digilent AXI MIG only, no hand-edit).
# Archives under results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/. Evidence class MIG_XSIM, not BOARD.
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH DDR-WAVEFRONT-00]
set migroot [file join $root vivado ip mig_7series_0 mig_7series_0]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}

set prj [file join $outdir wavefront_xsim.prj]
set fh [open $prj w]
puts $fh "# ddr_wavefront_00 — Digilent AXI MIG sim; do not hand-edit mig.prj"

foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/scorer/a7ng_termgen_lane.sv
  rtl/native_graph/scorer/a7ng_termgen_array.sv
  rtl/native_graph/scorer/a7ng_scorer_lane.sv
  rtl/native_graph/scorer/a7ng_scorer_array.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/frontier/a7ng_frontier_buckets.sv
  rtl/native_graph/topk/a7ng_ng02_core.sv
  rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv
  rtl/native_graph/memory/a7ng_cue_wavefront.sv
  rtl/native_graph/memory/a7ng_wavefront_mig_top.sv
  rtl/ddr/mig_native_wrap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_wavefront_mig.sv]\""

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
set xvlog_log [file join $outdir xvlog_wavefront.log]
if {[catch {exec $xvlog_bin -prj $prj -i $incdir > $xvlog_log 2>@1} vlog_rc]} {
  puts "xvlog_rc=$vlog_rc"
  set fp [open $xvlog_log r]
  puts [read $fp]
  close $fp
  puts XVLOG_FAIL
  exit 2
}
puts [read [open $xvlog_log r]]

set xelab_log [file join $outdir xelab_wavefront.log]
# Vivado 2026.1: default xelab ACCESS_VIOLATION on this MIG netlist; -mt off -O0 required.
if {[catch {exec $xelab_bin -mt off -O0 tb_a7ng_wavefront_mig glbl -s tb_a7ng_wavefront_mig_sim \
    -L unisims_ver -L unimacro_ver -L secureip -timescale 1ps/1ps > $xelab_log 2>@1} elab_rc]} {
  puts "xelab_rc=$elab_rc"
  set fp [open $xelab_log r]
  puts [read $fp]
  close $fp
  puts XELAB_FAIL
  exit 3
}
puts [read [open $xelab_log r]]

set log [file join $outdir xsim_wavefront.log]
if {[catch {exec $xsim_bin tb_a7ng_wavefront_mig_sim -runall > $log 2>@1} sim_rc]} {
  puts "xsim_rc=$sim_rc"
}
set fp [open $log r]
set sim_out [read $fp]
close $fp

# Distil the evidence rows so the archive has a readable metric file next to the raw log
set rows [file join $outdir METRIC_ROWS.txt]
set rf [open $rows w]
foreach line [split $sim_out "\n"] {
  if {[regexp {^(PREREG_|NOTE:|WF_|RUN_PASS|RUN_FAIL|A7NG_DDR_WAVEFRONT00)} $line]} {
    puts $rf $line
  }
}
close $rf
puts [read [open $rows r]]

if {[string match "*A7NG_DDR_WAVEFRONT00_XSIM_PASS*" $sim_out]} {
  puts A7NG_DDR_WAVEFRONT00_XSIM_OK
  exit 0
}
puts A7NG_DDR_WAVEFRONT00_NO_PASS
exit 5
