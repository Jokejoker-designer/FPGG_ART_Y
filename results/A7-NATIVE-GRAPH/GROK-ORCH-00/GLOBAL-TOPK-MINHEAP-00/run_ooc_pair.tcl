# Apples-to-apples OOC: frozen bitonic wavefront vs min-heap. 12.5 MHz. PROGRAM=NO.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set part xc7a100tcsg324-1
set_param general.maxThreads 8

proc ooc_one {root bag name files top} {
  close_project -quiet
  create_project -in_memory -part xc7a100tcsg324-1
  foreach f $files {
    read_verilog -sv [file join $root $f]
  }
  synth_design -mode out_of_context -top $top -flatten_hierarchy rebuilt
  create_clock -period 80.000 -name clk [get_ports clk]
  opt_design
  place_design
  route_design
  set util [file join $bag ${name}_util_route.rpt]
  set tim  [file join $bag ${name}_timing_route.rpt]
  report_utilization -file $util
  report_timing_summary -file $tim
  set lut [get_property SLICE_LUTS [get_designs]]
  puts "OOC_DONE name=$name top=$top"
}

set pkg  rtl/native_graph/pkg/a7ng_pkg.sv
set topk rtl/native_graph/topk/a7ng_topk.sv
set bitn rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
set heap rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv

ooc_one $root $bag bitonic [list $pkg $topk $bitn] a7ng_topk_wavefront_global
ooc_one $root $bag minheap [list $pkg $heap] a7ng_topk_wavefront_minheap
puts OOC_PAIR_DONE
exit 0
