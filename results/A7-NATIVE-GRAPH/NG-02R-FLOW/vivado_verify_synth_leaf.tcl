set root "D:/Jetking_sem4/SEM_4/arty-a7-online-lm"
set outdir "$root/results/A7-NATIVE-GRAPH/NG-02R-FLOW"
set logfile "$outdir/vivado_verify_synth_leaf.log"
file mkdir $outdir
create_project -in_memory -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
read_verilog -sv [list \
  $root/rtl/native_graph/pkg/a7ng_pkg.sv \
  $root/rtl/native_graph/scorer/a7ng_scorer_lane.sv \
  $root/rtl/native_graph/scorer/a7ng_scorer_array.sv \
  $root/rtl/native_graph/topk/a7ng_topk.sv \
  $root/rtl/native_graph/topk/a7ng_ng02_core.sv \
  $root/rtl/native_graph/frontier/a7ng_frontier_buckets.sv]
synth_design -mode out_of_context -top a7ng_ng02_core -part xc7a100tcsg324-1
set util [report_utilization -return_string]
set lut [regexp -inline {Slice LUTs\s*\|\s*([0-9]+)} $util]
set ff  [regexp -inline {Slice Registers\s*\|\s*([0-9]+)} $util]
set dsp [regexp -inline {DSPs\s*\|\s*([0-9]+)} $util]
puts "SYNTH_LEAF_OK top=a7ng_ng02_core"
puts "UTIL_SNIPPET_LUT=$lut"
puts "UTIL_SNIPPET_FF=$ff"
puts "UTIL_SNIPPET_DSP=$dsp"
# Also report DSP count via Tcl API
set dsps [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
set luts [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ LUT.* || REF_NAME =~ LUT*}]]
puts "DSP_CELLS=$dsps"
report_utilization -file $outdir/vivado_verify_synth_leaf_util.rpt
puts SYNTH_LEAF_PASS
exit 0
