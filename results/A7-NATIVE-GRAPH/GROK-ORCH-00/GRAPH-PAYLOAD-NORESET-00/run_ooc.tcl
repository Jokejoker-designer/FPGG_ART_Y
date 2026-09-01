# OOC each GRAPH-PAYLOAD-NORESET changed module. 12.5 MHz. PROGRAM=NO.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set part xc7a100tcsg324-1
set_param general.maxThreads 8

proc ooc_one {root bag part top files tag} {
  close_project -quiet
  create_project -in_memory -part $part
  foreach f $files {
    read_verilog -sv [file join $root $f]
  }
  synth_design -mode out_of_context -top $top -flatten_hierarchy rebuilt
  create_clock -period 80.000 -name clk [get_ports clk]
  opt_design
  place_design
  route_design
  report_utilization -file [file join $bag "ooc_${tag}_util_route.rpt"]
  report_utilization -hierarchical -file [file join $bag "ooc_${tag}_util_route_hier.rpt"]
  report_timing_summary -file [file join $bag "ooc_${tag}_timing_route.rpt"]
  puts "OOC_${tag}_DONE"
}

ooc_one $root $bag $part a7ng_termgen_lane_fold6 [list \
  rtl/native_graph/pkg/a7ng_pkg.sv \
  rtl/native_graph/scorer/a7ng_termgen_lane_fold6.sv] termgen

ooc_one $root $bag $part a7ng_topk_stream_minheap [list \
  rtl/native_graph/pkg/a7ng_pkg.sv \
  rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] heap

ooc_one $root $bag $part a7ng_ng02_core [list \
  rtl/native_graph/pkg/a7ng_pkg.sv \
  rtl/native_graph/scorer/a7ng_scorer_lane.sv \
  rtl/native_graph/scorer/a7ng_scorer_array.sv \
  rtl/native_graph/topk/a7ng_topk_stream_minheap.sv \
  rtl/native_graph/frontier/a7ng_frontier_buckets.sv \
  rtl/native_graph/topk/a7ng_ng02_core.sv] ng02

puts "OOC_GRAPH_PAYLOAD_NORESET_DONE"
exit 0
