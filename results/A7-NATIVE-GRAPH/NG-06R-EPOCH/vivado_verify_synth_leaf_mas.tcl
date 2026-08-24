# VERIFY_ONLY ng06_epoch — synth leaf a7ng_multi_agent_share (epoch RTL)
set root "D:/Jetking_sem4/SEM_4/arty-a7-online-lm"
set outdir "$root/results/A7-NATIVE-GRAPH/NG-06R-EPOCH"
file mkdir $outdir
create_project -in_memory -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
read_verilog -sv [list $root/rtl/native_graph/share/a7ng_multi_agent_share.sv]
synth_design -mode out_of_context -top a7ng_multi_agent_share -part xc7a100tcsg324-1 \
  -flatten_hierarchy none -directive RuntimeOptimized
set dsps [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
puts "SYNTH_LEAF_MAS_OK top=a7ng_multi_agent_share DSP_CELLS=$dsps"
report_utilization -file $outdir/vivado_verify_synth_leaf_mas_util.rpt
if {$dsps != 0} {
  puts "DSP_GATE_FAIL DSP_CELLS=$dsps"
  exit 3
}
puts SYNTH_LEAF_MAS_PASS
exit 0
