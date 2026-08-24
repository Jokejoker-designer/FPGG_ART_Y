# VERIFY_ONLY ng06_epoch — OOC synth leaf (no bitstream / no frozen overwrite)
set root "D:/Jetking_sem4/SEM_4/arty-a7-online-lm"
set outdir "$root/results/A7-NATIVE-GRAPH/NG-06R-EPOCH"
file mkdir $outdir
create_project -in_memory -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]

# Leaf 1: wide_dispatch OOC top (share + epoch tie-offs)
read_verilog -sv [list \
  $root/rtl/native_graph/share/a7ng_multi_agent_share.sv \
  $root/rtl/native_graph/share/a7ng_wide_dispatch_ooc_top.sv]
synth_design -mode out_of_context -top a7ng_wide_dispatch_ooc_top -part xc7a100tcsg324-1 \
  -flatten_hierarchy none -directive RuntimeOptimized
set dsps_share [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
puts "SYNTH_LEAF_SHARE_OK top=a7ng_wide_dispatch_ooc_top DSP_CELLS=$dsps_share"
report_utilization -file $outdir/vivado_verify_synth_leaf_share_util.rpt
puts "SYNTH_LEAF_SHARE_PASS DSP_CELLS=$dsps_share"

# Leaf 2: ctx_prune (epoch DROP_STALE)
close_design
read_verilog -sv [list $root/rtl/native_graph/prune/a7ng_ctx_prune.sv]
synth_design -mode out_of_context -top a7ng_ctx_prune -part xc7a100tcsg324-1 \
  -flatten_hierarchy none -directive RuntimeOptimized
set dsps_prune [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
puts "SYNTH_LEAF_PRUNE_OK top=a7ng_ctx_prune DSP_CELLS=$dsps_prune"
report_utilization -file $outdir/vivado_verify_synth_leaf_prune_util.rpt
puts "SYNTH_LEAF_PRUNE_PASS DSP_CELLS=$dsps_prune"

if {$dsps_share != 0 || $dsps_prune != 0} {
  puts "DSP_GATE_FAIL share=$dsps_share prune=$dsps_prune"
  exit 3
}
puts SYNTH_LEAF_PASS
exit 0
