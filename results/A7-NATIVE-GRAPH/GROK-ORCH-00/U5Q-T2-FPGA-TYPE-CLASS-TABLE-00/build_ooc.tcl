# U5Q-T2 OOC. No bitstream. Timing estimate only, not full-chip fit.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
file mkdir [file join $bag ooc]
create_project -force t2tc_ooc [file join $bag ooc] -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
add_files -norecurse [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_scan.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_ooc_top.sv]]
set_property include_dirs [list $bag] [current_fileset]
set_property top a7ng_typeclass_ooc_top [current_fileset]
synth_design -mode out_of_context -top a7ng_typeclass_ooc_top -part xc7a100tcsg324-1
report_utilization -file [file join $bag report_utilization_ooc.rpt]
create_clock -period 10.000 -name clk [get_ports clk]
report_timing_summary -file [file join $bag report_timing_ooc.rpt]
puts "U5Q_T2_OOC_DONE"
exit 0
