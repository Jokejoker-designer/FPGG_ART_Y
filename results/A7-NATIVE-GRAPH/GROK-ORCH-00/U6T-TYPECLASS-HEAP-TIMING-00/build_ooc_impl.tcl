# U6T: OOC implement of TYPE_CLASS retrieval. No bitstream. Internal timing only.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
file mkdir [file join $bag ooc]
create_project -force u6t_ooc [file join $bag ooc] -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
add_files -norecurse [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_scan.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_materialize.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_u6_typeclass_retrieval.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_u6_typeclass_ooc_top.sv]]
set_property include_dirs [list \
  [file join $root rtl/native_graph/query] \
  [file join $root rtl/native_graph/control] \
  [file join $root rtl/native_graph/memory] \
  [file join $bag ../U3Q-R3-STRUCTURED-QUERY-FEATURE-00]] [current_fileset]
set_property top a7ng_u6_typeclass_ooc_top [current_fileset]
synth_design -mode out_of_context -top a7ng_u6_typeclass_ooc_top -part xc7a100tcsg324-1
create_clock -period 10.000 -name clk [get_ports clk]
foreach p [all_inputs] {
  if {[get_property NAME $p] ne "clk"} {
    set_false_path -from $p
  }
}
foreach p [all_outputs] {
  set_false_path -to $p
}
opt_design
place_design
route_design
report_timing_summary -file [file join $bag report_timing_route.rpt]
report_utilization -file [file join $bag report_utilization_route.rpt]
report_route_status -file [file join $bag report_route_status.rpt]
set wns [get_property SLACK [get_timing_paths -setup -max_paths 1]]
set whs [get_property SLACK [get_timing_paths -hold -max_paths 1]]
puts "U6T_OOC_ROUTE_WNS=$wns"
puts "U6T_OOC_ROUTE_WHS=$whs"
exit 0
