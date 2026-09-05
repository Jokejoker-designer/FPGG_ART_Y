# U6 TYPECLASS OOC. No bitstream. Timing estimate only, not full-chip fit.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
file mkdir [file join $bag ooc]
create_project -force u6tc_ooc [file join $bag ooc] -part xc7a100tcsg324-1
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
report_utilization -file [file join $bag report_utilization_ooc.rpt]
create_clock -period 10.000 -name clk [get_ports clk]
report_timing_summary -file [file join $bag report_timing_ooc.rpt]
puts "U6TC_OOC_DONE"
exit 0
