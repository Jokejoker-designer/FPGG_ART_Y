# A7-LM-00: xc7a100t wrapper around frozen Basys LM-05 core. No DDR.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm00]
set out_dir [file join $root_dir build out]
file mkdir $build_dir
file mkdir $out_dir

set part_name xc7a100tcsg324-1
if {[llength [get_parts -quiet $part_name]] == 0} {
    puts stderr "ERROR: Vivado installation does not contain $part_name."
    exit 2
}

create_project -force a7lm00 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

set rtl_files [list \
    [file join $root_dir rtl board basys3_clock_gen.sv] \
    [file join $root_dir rtl board sync_bits.sv] \
    [file join $root_dir rtl board uart_tx.sv] \
    [file join $root_dir rtl board uart_rx.sv] \
    [file join $root_dir rtl lm lm03_pkg.sv] \
    [file join $root_dir rtl lm weight_bram4096.sv] \
    [file join $root_dir rtl lm act_ram_tdp32.sv] \
    [file join $root_dir rtl lm ckpt_bram3200.sv] \
    [file join $root_dir rtl lm mac64.sv] \
    [file join $root_dir rtl lm floordiv_s48.sv] \
    [file join $root_dir rtl lm isqrt32.sv] \
    [file join $root_dir rtl lm context_buffer.sv] \
    [file join $root_dir rtl lm argmax32.sv] \
    [file join $root_dir rtl lm lm02_tx.sv] \
    [file join $root_dir rtl lm tiny_gpt05_core.sv] \
    [file join $root_dir rtl lm lm05_link.sv] \
    [file join $root_dir rtl board arty_a7_100_top.sv]]

add_files -norecurse $rtl_files
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints arty_a7_100.xdc]
set_property top arty_a7_100_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTHESIS A7-LM-00 ==="
synth_design -top arty_a7_100_top -part $part_name -flatten_hierarchy rebuilt
write_checkpoint -force [file join $out_dir a7lm00_post_synth.dcp]
report_utilization -file [file join $out_dir a7lm00_utilization_synth.rpt]
report_timing_summary -delay_type max -max_paths 10 -file [file join $out_dir a7lm00_timing_synth.rpt]

puts "=== IMPLEMENTATION A7-LM-00 ==="
opt_design
place_design
phys_opt_design
route_design
phys_opt_design
write_checkpoint -force [file join $out_dir a7lm00_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm00_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm00_utilization_route.rpt]

set max_path [get_timing_paths -quiet -delay_type max -max_paths 1]
set wns [get_property SLACK [lindex $max_path 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.0} {
    puts stderr "ERROR: timing is not closed; WNS=$wns"
    exit 4
}
write_bitstream -force [file join $out_dir arty_a7_lm00.bit]
puts "A7_LM00_BUILD_PASS bitstream=[file join $out_dir arty_a7_lm00.bit] WNS=$wns"
