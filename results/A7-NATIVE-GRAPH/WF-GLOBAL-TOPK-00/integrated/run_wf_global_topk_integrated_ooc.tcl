# OOC synth/impl — wf_global_topk_integrated_00 VERIFY_ONLY (a7-vivado-gate)
# Target: a7ng_ddr_wavefront_top (patched global Top-K hook) — no MIG, no bitstream
set root [file normalize [file join [file dirname [info script]] ../../../..]]
set outdir [file join $root results A7-NATIVE-GRAPH WF-GLOBAL-TOPK-00 integrated]
file mkdir $outdir
set part xc7a100tcsg324-1
set clk_period 10.000
set tag wavefront_integrated

set build [file join $outdir vivado_${tag}_ooc]
file mkdir $build
create_project -force ${tag}_ooc $build -part $part
set_property target_language Verilog [current_project]

set wf_rtl {
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
}
foreach f $wf_rtl {
  add_files [file join $root {*}$f]
}
set_property top a7ng_ddr_wavefront_top [current_fileset]
set_property file_type {SystemVerilog} [get_files *.sv]

set clk_xdc "create_clock -period $clk_period -name clk \[get_ports clk\]"
set wf_xdc "${clk_xdc}\nset_false_path -from \[get_ports start_i\]\nset_false_path -from \[get_ports flush_i\]"
set xdc [file join $outdir ${tag}_ooc.xdc]
set fh [open $xdc w]
puts $fh $wf_xdc
close $fh
add_files -fileset constrs_1 $xdc

puts "=== SYNTH integrated wavefront top=a7ng_ddr_wavefront_top ==="
if {[catch {synth_design -top a7ng_ddr_wavefront_top -part $part -mode out_of_context} serr]} {
  puts "INTEGRATED_WAVEFRONT_SYNTH_FAIL $serr"
  close_project
  exit 1
}
report_utilization -file [file join $outdir ${tag}_util_synth.rpt]
opt_design
place_design
route_design
report_utilization -file [file join $outdir ${tag}_util_route.rpt]
report_timing_summary -file [file join $outdir ${tag}_timing_route.rpt]

set rpt [file join $outdir ${tag}_timing_route.rpt]
set wns NA; set tns NA; set whs NA; set ths NA
if {[file exists $rpt]} {
  set fh [open $rpt r]
  set txt [read $fh]
  close $fh
  if {[regexp {WNS\(ns\)\s+(-?[0-9.]+)} $txt -> wns]} {}
  if {[regexp {TNS\(ns\)\s+(-?[0-9.]+)} $txt -> tns]} {}
  if {[regexp {WHS\(ns\)\s+(-?[0-9.]+)} $txt -> whs]} {}
  if {[regexp {THS\(ns\)\s+(-?[0-9.]+)} $txt -> ths]} {}
}
set util [file join $outdir ${tag}_util_route.rpt]
set lut NA; set ff NA; set bram NA; set dsp NA
if {[file exists $util]} {
  set fh [open $util r]
  set utxt [read $fh]
  close $fh
  if {[regexp {Slice LUTs\*?\s+\|\s+([0-9]+)} $utxt -> lut]} {}
  if {[regexp {Slice Registers\s+\|\s+([0-9]+)} $utxt -> ff]} {}
  if {[regexp {Block RAM Tile\s+\|\s+([0-9.]+)} $utxt -> bram]} {}
  if {[regexp {DSPs\s+\|\s+([0-9]+)} $utxt -> dsp]} {}
}
puts "INTEGRATED_WAVEFRONT_OOC_WNS=$wns"
puts "INTEGRATED_WAVEFRONT_OOC_TNS=$tns"
puts "INTEGRATED_WAVEFRONT_OOC_WHS=$whs"
puts "INTEGRATED_WAVEFRONT_OOC_THS=$ths"
puts "INTEGRATED_WAVEFRONT_OOC_LUT=$lut"
puts "INTEGRATED_WAVEFRONT_OOC_FF=$ff"
puts "INTEGRATED_WAVEFRONT_OOC_BRAM=$bram"
puts "INTEGRATED_WAVEFRONT_OOC_DSP=$dsp"
close_project
puts "A7NG_WF_GLOBAL_TOPK_INTEGRATED_OOC_DONE"
