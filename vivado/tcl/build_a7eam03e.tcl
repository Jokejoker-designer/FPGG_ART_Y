# A7-EAM-03E-A0 encoder only. Never write LM or frozen EAM bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7eam03e]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-03E]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $res_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_eam03e.bit]
if {[string match *arty_a7_lm* [file tail $bitfile]]} {
    puts stderr "REFUSE: EAM bit path must not be an LM name"
    exit 2
}

create_project -force a7eam03e $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/eam a7eam03e_pkg.sv] \
    [file join $root_dir rtl/eam eam03e_core.sv] \
    [file join $root_dir rtl/eam eam03e_uart.sv] \
    [file join $root_dir rtl/board uart_rx.sv] \
    [file join $root_dir rtl/board uart_tx.sv] \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/board arty_a7_eam03e_top.sv]]
add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7eam01r_board.xdc]]
set_property top arty_a7_eam03e_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-EAM-03E-A0 ==="
synth_design -top arty_a7_eam03e_top -part $part_name -flatten_hierarchy rebuilt
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_checkpoint -force [file join $out_dir a7eam03e_post_synth.dcp]

puts "=== IMPLEMENT A7-EAM-03E-A0 ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive Explore} perr]} { puts "WARN: phys_opt $perr" }
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7eam03e_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7eam03e_timing_route.rpt]
report_utilization -file [file join $out_dir a7eam03e_utilization_route.rpt]

set cfgbvs [get_property CFGBVS [current_design]]
set cfgv   [get_property CONFIG_VOLTAGE [current_design]]
if {$cfgbvs ne "VCCO" || $cfgv != 3.3} {
    puts stderr "ERROR: CFGBVS/CONFIG_VOLTAGE"
    exit 3
}
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force $bitfile
puts "WROTE $bitfile"
puts "A7_EAM03E_BOARD_BIT_OK"
