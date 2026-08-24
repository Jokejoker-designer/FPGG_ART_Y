# A7-LM-03: 25K 2-layer/2-head. Requires frozen 00/01/02 bits. Writes arty_a7_lm03.bit only.
# Do not program the resulting bit until post-route one-full funcsim matches oracle.
# Contract stays OPEN. Do not start A7-LM-04.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm03]
set out_dir [file join $root_dir build out]
file mkdir $build_dir
file mkdir $out_dir

set part_name xc7a100tcsg324-1
create_project -force a7lm03 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

add_files -norecurse [list \
    [file join $root_dir rtl board sync_bits.sv] \
    [file join $root_dir rtl board uart_tx.sv] \
    [file join $root_dir rtl board uart_rx.sv] \
    [file join $root_dir rtl lm lm02_tx.sv] \
    [file join $root_dir rtl board clkdiv2.sv] \
    [file join $root_dir rtl lm a7lm03_pkg.sv] \
    [file join $root_dir rtl lm isqrt32.sv] \
    [file join $root_dir rtl lm floordiv_s48.sv] \
    [file join $root_dir rtl lm weight_bram25k.sv] \
    [file join $root_dir rtl lm act_ram32k.sv] \
    [file join $root_dir rtl lm tiny_gpt25k_core.sv] \
    [file join $root_dir rtl board arty_a7_lm03_top.sv]]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints arty_a7_lm03.xdc]]
set_property top arty_a7_lm03_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTHESIS A7-LM-03 ==="
synth_design -top arty_a7_lm03_top -part $part_name -flatten_hierarchy rebuilt -directive PerformanceOptimized
write_checkpoint -force [file join $out_dir a7lm03_post_synth.dcp]
report_utilization -file [file join $out_dir a7lm03_utilization_synth.rpt]

puts "=== IMPLEMENT A7-LM-03 ==="
opt_design -directive ExploreWithRemap
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore
phys_opt_design -directive AggressiveExplore
write_checkpoint -force [file join $out_dir a7lm03_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm03_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm03_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.0} {
    puts stderr "ERROR: WNS=$wns"
    exit 4
}
foreach frozen {arty_a7_lm00.bit arty_a7_lm01.bit arty_a7_lm02.bit} {
    if {![file exists [file join $out_dir $frozen]]} {
        puts stderr "ERROR: refuse to write LM-03 without frozen $frozen"
        exit 5
    }
}
write_bitstream -force [file join $out_dir arty_a7_lm03.bit]
puts "A7_LM03_BUILD_PASS bitstream=[file join $out_dir arty_a7_lm03.bit] WNS=$wns"
