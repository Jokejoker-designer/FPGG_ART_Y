# Lite integrate: 16-lane scorer + episode bank (no MIG/LM). Never overwrite frozen bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7ng_lite]
set out_dir    [file join $root_dir build out]
file mkdir $build_dir
file mkdir $out_dir
set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_integrate_lite.bit]

create_project -force a7ng_lite $build_dir -part $part_name
set_property target_language Verilog [current_project]
add_files -norecurse [list \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_episode_bank.sv] \
    [file join $root_dir rtl/board arty_a7_ng_integrate_lite_top.sv]]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7ng02.xdc]
set_property top arty_a7_ng_integrate_lite_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top arty_a7_ng_integrate_lite_top -part $part_name
opt_design
place_design
route_design
set rpt [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE]
file mkdir $rpt
report_timing_summary -file [file join $rpt lite_timing.rpt]
report_utilization -file [file join $rpt lite_util.rpt]
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "LITE_WNS=$wns"
if {$wns < 0} { puts stderr "ERROR WNS"; exit 5 }
write_bitstream -force $bitfile
puts "LITE_BIT=$bitfile"
puts "A7NG_INTEGRATE_LITE_DONE"
