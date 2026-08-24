# NG-02 integrated scorer+topk+frontier impl. Never overwrite frozen bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7ng02]
set out_dir    [file join $root_dir build out]
file mkdir $build_dir
file mkdir $out_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng02.bit]
foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: NG-02 bit path collides with frozen artifact"
        exit 2
    }
}

create_project -force a7ng02 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/topk a7ng_topk.sv] \
    [file join $root_dir rtl/native_graph/frontier a7ng_frontier_buckets.sv] \
    [file join $root_dir rtl/native_graph/topk a7ng_ng02_core.sv] \
    [file join $root_dir rtl/board arty_a7_ng02_top.sv]]
add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints a7ng02.xdc]]
set_property top arty_a7_ng02_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-NG-02 ==="
synth_design -top arty_a7_ng02_top -part $part_name -flatten_hierarchy none
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_checkpoint -force [file join $out_dir a7ng02_post_synth.dcp]

puts "=== IMPLEMENT A7-NG-02 ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN: phys_opt $perr" }
route_design
write_checkpoint -force [file join $out_dir a7ng02_post_route.dcp]

set rpt_dir [file join $root_dir results A7-NATIVE-GRAPH NG-02]
file mkdir $rpt_dir
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir a7ng02_timing_route.rpt]
report_utilization -file [file join $rpt_dir a7ng02_utilization_route.rpt]

set lane_cells [get_cells -hier -quiet *u_lane*]
set lane_count [llength $lane_cells]
puts "NG02_LANE_INSTANCES=$lane_count"
if {$lane_count != 16} {
    puts stderr "ERROR: expected 16 physical lanes, got $lane_count"
    exit 4
}

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "NG02_WNS=$wns"
if {$wns < 0} {
    puts stderr "ERROR: WNS < 0 ($wns)"
    exit 5
}

write_bitstream -force $bitfile
puts "NG02_BIT=$bitfile"
puts "A7NG02_IMPL_DONE"
