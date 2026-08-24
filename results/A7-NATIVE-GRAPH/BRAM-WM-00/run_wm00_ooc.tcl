# OOC synth/impl for a7ng_wm00_top — util + timing @ 100 MHz (no LM-06, no board program)
set root [file normalize [file join [file dirname [info script]] ../../..]]
set outdir [file join $root results/A7-NATIVE-GRAPH/BRAM-WM-00]
file mkdir $outdir
set part xc7a100tcsg324-1

create_project -force wm00_ooc [file join $outdir vivado_wm00_ooc] -part $part
set_property target_language Verilog [current_project]

add_files [list \
  [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_owner.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_synth_ddr.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_cand_buf.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_frontier.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_evidence.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_learn_upd.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_pe_iface.sv] \
  [file join $root rtl/native_graph/memory a7ng_wm00_top.sv]]
set_property top a7ng_wm00_top [current_fileset]
set_property file_type {SystemVerilog} [get_files *.sv]

# OOC clock constraint
set xdc [file join $outdir wm00_ooc.xdc]
set fh [open $xdc w]
puts $fh {create_clock -period 10.000 -name clk [get_ports clk]}
close $fh
add_files -fileset constrs_1 $xdc

synth_design -top a7ng_wm00_top -part $part -mode out_of_context
report_utilization -file [file join $outdir util_synth.rpt]
opt_design
place_design
route_design
report_utilization -file [file join $outdir util_route.rpt]
report_timing_summary -file [file join $outdir timing_route.rpt]
report_utilization -hierarchical -file [file join $outdir util_hier.rpt]

# Extract key numbers
set lut [get_property SLICE_LUTS [get_designs]]
# Prefer report parse
set ufile [file join $outdir util_route.rpt]
set tfile [file join $outdir timing_route.rpt]
puts "WM00_OOC_UTIL_ROUTE=$ufile"
puts "WM00_OOC_TIMING=$tfile"
puts "A7NG_BRAM_WM00_OOC_DONE"
