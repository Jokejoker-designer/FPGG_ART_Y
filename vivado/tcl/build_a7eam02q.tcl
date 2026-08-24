# A7-EAM-02Q board: Q1 + 01R. Never write arty_a7_lm*.bit.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7eam02q]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-02Q]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $res_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_eam02q.bit]
if {[string match *arty_a7_lm* [file tail $bitfile]]} {
    puts stderr "REFUSE: EAM bit path must not be an LM name"
    exit 2
}

create_project -force a7eam02q $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/eam a7eam00_pkg.sv] \
    [file join $root_dir rtl/eam a7eam01r_pkg.sv] \
    [file join $root_dir rtl/eam eam_tdp256.sv] \
    [file join $root_dir rtl/eam eam01r_ibank.sv] \
    [file join $root_dir rtl/eam eam01r_core.sv] \
    [file join $root_dir rtl/eam eam02q_q1.sv] \
    [file join $root_dir rtl/eam eam02q_q1_signs.svh] \
    [file join $root_dir rtl/eam eam02q_uart.sv] \
    [file join $root_dir rtl/board uart_rx.sv] \
    [file join $root_dir rtl/board uart_tx.sv] \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/board arty_a7_eam02q_top.sv]]
set_property include_dirs [list [file join $root_dir rtl/eam]] [current_fileset]
add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7eam01r_board.xdc]]
set_property top arty_a7_eam02q_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-EAM-02Q BOARD ==="
synth_design -top arty_a7_eam02q_top -part $part_name -flatten_hierarchy rebuilt
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_checkpoint -force [file join $out_dir a7eam02q_post_synth.dcp]
report_utilization -file [file join $out_dir a7eam02q_utilization_synth.rpt]
report_ram_utilization -file [file join $out_dir a7eam02q_ram_synth.rpt]

set n_dsp [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]
puts "INFER dsp=$n_dsp"
if {$n_dsp != 0} {
    puts stderr "ERROR: Q1 must be 0 DSP, got $n_dsp"
    exit 4
}

puts "=== IMPLEMENT A7-EAM-02Q ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive Explore} perr]} { puts "WARN: phys_opt $perr" }
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7eam02q_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7eam02q_timing_route.rpt]
report_utilization -file [file join $out_dir a7eam02q_utilization_route.rpt]

set cfgbvs [get_property CFGBVS [current_design]]
set cfgv   [get_property CONFIG_VOLTAGE [current_design]]
puts "CONFIG CFGBVS=$cfgbvs CONFIG_VOLTAGE=$cfgv"
if {$cfgbvs ne "VCCO" || $cfgv != 3.3} {
    puts stderr "ERROR: CFGBVS/CONFIG_VOLTAGE not Arty-A7 3.3V"
    exit 3
}

set wns 0.0
set tns 0.0
set trpt [file join $out_dir a7eam02q_timing_route.rpt]
set fh [open $trpt r]
set txt [read $fh]
close $fh
if {[regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s+([-0-9.]+)\s+([-0-9.]+)} $txt -> wns_s tns_s]} {
    set wns $wns_s
    set tns $tns_s
}
puts "POST_ROUTE_WNS=$wns TNS=$tns"
if {$wns < 0.0 || abs($tns) > 0.0005} {
    puts stderr "ERROR: timing fail WNS=$wns TNS=$tns"
    exit 5
}

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force $bitfile
puts "WROTE $bitfile"
puts "A7_EAM02Q_BOARD_BIT_OK WNS=$wns dsp=$n_dsp"
