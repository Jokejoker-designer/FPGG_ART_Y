# OOC P&R for a7ng_learned_prior_graph. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set part xc7a100tcsg324-1
set_param general.maxThreads 8
close_project -quiet
create_project -in_memory -part $part
read_verilog -sv [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
read_verilog -sv [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv]
read_verilog -sv [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv]
read_verilog -sv [file join $root rtl/native_graph/learn/a7ng_context_delta.sv]
read_verilog -sv [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv]
read_verilog -sv [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv]
read_verilog -sv [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv]
synth_design -mode out_of_context -top a7ng_learned_prior_graph -flatten_hierarchy rebuilt
create_clock -period 80.000 -name clk [get_ports clk]
opt_design
place_design
route_design
report_utilization -file [file join $bag ooc_util_route.rpt]
report_utilization -hierarchical -file [file join $bag ooc_util_route_hier.rpt]
report_timing_summary -file [file join $bag ooc_timing_route.rpt]
report_cdc -file [file join $bag ooc_cdc.rpt]
puts OOC_C9_LEARNED_PRIOR_GRAPH_DONE
exit 0
