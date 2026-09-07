# U3Q-R3 OOC UTILIZATION-ONLY. No bitstream. No timing claim.
# DSP must be 0. Missing DSP row means 0 DSP cells.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
file mkdir [file join $bag ooc]
create_project -force u3qr3_ooc [file join $bag ooc] -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
add_files -norecurse [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv] \
  [file join $root rtl/native_graph/query/a7ng_query_struct_ooc_top.sv]]
set_property include_dirs [list \
  [file join $root rtl/native_graph/query] \
  [file join $root rtl/native_graph/control]] [current_fileset]
set_property top a7ng_query_struct_ooc_top [current_fileset]
synth_design -mode out_of_context -top a7ng_query_struct_ooc_top -part xc7a100tcsg324-1
report_utilization -file [file join $bag report_utilization_ooc.rpt]
puts "U3Q_R3_OOC_UTILIZATION_ONLY_NO_TIMING_CLAIM"
# No create_clock / no report_timing_summary as evidence.
set utxt [read [open [file join $bag report_utilization_ooc.rpt] r]]
set dsp 0
if {[regexp {\|\s+DSPs\s+\|\s+(\d+)} $utxt -> d]} { set dsp $d }
if {[regexp {DSP48E1} $utxt] && $dsp == 0} {
  if {[regexp {\| DSP48E1s\s+\|\s+(\d+)} $utxt -> d2]} { set dsp $d2 }
}
puts "OOC_DSP=$dsp"
if {$dsp != 0} {
  puts "U3Q_R3_OOC_DSP_FAIL"
  exit 4
}
puts "U3Q_R3_OOC_DSP0_PASS"
exit 0
