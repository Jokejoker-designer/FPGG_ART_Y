# OOC glue only — do not instantiate persist/LM/TopK.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set part xc7a100tcsg324-1
set_param general.maxThreads 8
close_project -quiet
create_project -in_memory -part $part
read_verilog -sv [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
read_verilog -sv [file join $root rtl/native_graph/integrate/a7ng_teacher_off_glue.sv]
synth_design -mode out_of_context -top a7ng_teacher_off_glue -flatten_hierarchy rebuilt
create_clock -period 80.000 -name clk [get_ports clk]
opt_design
place_design
route_design
report_utilization -file [file join $bag ooc_glue_util_route.rpt]
report_utilization -hierarchical -file [file join $bag ooc_glue_util_hier.rpt]
report_timing_summary -file [file join $bag ooc_glue_timing_route.rpt]
puts OOC_TEACHER_OFF_GLUE_DONE
exit 0
