# NG-01 16-lane scorer — synth+impl. Law a7ng-scorer-v0.
# Never write LM / 01R / 02M / A0.3 frozen bit names.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7ng01]
set out_dir    [file join $root_dir build out]
file mkdir $build_dir
file mkdir $out_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng01_scorer.bit]
foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: NG-01 bit path collides with frozen artifact"
        exit 2
    }
}

create_project -force a7ng01 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/board arty_a7_ng01_scorer_top.sv]]
add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints a7ng01_scorer.xdc]]
set_property top arty_a7_ng01_scorer_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-NG-01 ==="
synth_design -top arty_a7_ng01_scorer_top -part $part_name -flatten_hierarchy none
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_checkpoint -force [file join $out_dir a7ng01_post_synth.dcp]

puts "=== IMPLEMENT A7-NG-01 ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN: phys_opt $perr" }
route_design
write_checkpoint -force [file join $out_dir a7ng01_post_route.dcp]

set rpt_dir [file join $root_dir results A7-NATIVE-GRAPH NG-01]
file mkdir $rpt_dir
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir a7ng01_timing_route.rpt]
report_utilization -file [file join $rpt_dir a7ng01_utilization_route.rpt]

# Count physical scorer lane instances (must remain 16 distinct)
set lane_cells [get_cells -hier -quiet *u_lane*]
if {[llength $lane_cells] == 0} {
    set lane_cells [get_cells -hier -quiet -filter {REF_NAME == a7ng_scorer_lane || ORIG_REF_NAME == a7ng_scorer_lane}]
}
set lane_count [llength $lane_cells]
puts "NG01_LANE_INSTANCES=$lane_count"
puts "NG01_LANE_CELLS=$lane_cells"
if {$lane_count != 16} {
    puts stderr "ERROR: expected 16 physical lanes, got $lane_count"
    exit 4
}

# Parse WNS/TNS from timing report
set tw [open [file join $rpt_dir a7ng01_timing_route.rpt] r]
set timing_txt [read $tw]
close $tw
puts "NG01_TIMING_SNIPPET"
# Gate: refuse bit if WNS negative — check slack line via report_property
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "NG01_WNS=$wns"
if {$wns < 0} {
    puts stderr "ERROR: WNS < 0 ($wns)"
    exit 5
}

write_bitstream -force $bitfile
puts "NG01_BIT=$bitfile"
puts "A7NG01_IMPL_DONE"
