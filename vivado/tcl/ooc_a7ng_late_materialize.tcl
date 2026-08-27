# OOC synth of Phase C late-materialize core. DSP must be 0.
# Evidence_class=OOC. Not BOARD. Not UART pred=664.
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results/A7-NATIVE-GRAPH/GRAPH-LATE-MATERIALIZE-00]
file mkdir $outdir
set part xc7a100tcsg324-1
create_project -in_memory -part $part
set_property target_language Verilog [current_project]
read_verilog -sv [list \
  [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/memory a7ng_late_materialize.sv]]
read_xdc [file join $root constraints a7ng_wide_dispatch_ooc.xdc]
if {[catch {synth_design -mode out_of_context -top a7ng_late_materialize -part $part} serr]} {
  puts stderr "ERROR synth: $serr"
  exit 2
}
report_utilization -file [file join $outdir ooc_util.rpt]
set dsps [llength [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ DSP.*}]]
puts "OOC_DSP_CELLS=$dsps"
if {$dsps != 0} {
  puts A7NG_LATE_MAT_OOC_DSP_FAIL
  exit 5
}
puts A7NG_LATE_MAT_OOC_DSP0_PASS
exit 0
