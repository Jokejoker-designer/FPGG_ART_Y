# PHASE2-G2-CONTEXT-DELTA-RTL-00 OOC. 12.5 MHz period 80.000 ns. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set part xc7a100tcsg324-1
set_param general.maxThreads 8
close_project -quiet
create_project -in_memory -part $part
read_verilog -sv [file join $root rtl/native_graph/learn/a7ng_context_delta.sv]
synth_design -mode out_of_context -top a7ng_context_delta -flatten_hierarchy rebuilt
create_clock -period 80.000 -name clk [get_ports clk]
opt_design
place_design
route_design
report_utilization -file [file join $bag ooc_util_route.rpt]
report_utilization -hierarchical -file [file join $bag ooc_util_route_hier.rpt]
report_timing_summary -file [file join $bag ooc_timing_route.rpt]
report_control_sets -verbose -file [file join $bag ooc_control_sets.rpt]
puts "OOC_CONTEXT_DELTA_DONE"
exit 0
