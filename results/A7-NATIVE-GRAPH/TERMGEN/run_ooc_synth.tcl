# OOC synth TermGen array — DSP/LUT/FF + 16 keep_hierarchy lanes. Not BOARD_PASS.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set outdir [file join $root results A7-NATIVE-GRAPH TERMGEN]
file mkdir $outdir

set part xc7a100tcsg324-1
create_project -in_memory -part $part
set_property target_language Verilog [current_project]

read_verilog -sv [list \
  [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_lane.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/scorer a7ng_termgen_ooc_top.sv]]

synth_design -top a7ng_termgen_ooc_top -part $part -mode out_of_context
create_clock -period 10.000 -name clk [get_ports clk]
report_utilization -file [file join $outdir ooc_util.rpt]
report_timing_summary -file [file join $outdir ooc_timing.rpt]

set lanes [llength [get_cells -hier -filter {NAME =~ *g_tg*}]]
set dsp_n [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
puts "TERMGEN_OOC_LANE_CELLS=$lanes"
puts "TERMGEN_OOC_DSP=$dsp_n"
set paths [get_timing_paths -max_paths 1 -nworst 1 -setup]
if {[llength $paths] > 0} {
  set wns [get_property SLACK $paths]
  puts "TERMGEN_OOC_WNS=$wns"
} else {
  puts "TERMGEN_OOC_WNS=NA"
}
puts "TERMGEN_OOC_DONE"
