# measure_ng06r_wide_ooc.tcl — synth/place/route N_WAY=16 compact allocator @ 100 MHz
# OOC timing vehicle = a7ng_wide_alloc_ooc (same pair-k semantics as share).
# Full share depth/hotset proven by XSim. Never overwrite frozen bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng06r_wide]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH NG-06R-WIDE]
file mkdir $build_dir
file mkdir $rpt_dir

set part_name xc7a100tcsg324-1
set top_name  a7ng_wide_dispatch_ooc_top

create_project -force a7ng06r_wide $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse \
  [file join $root_dir rtl/native_graph/share a7ng_wide_dispatch_ooc_top.sv]
add_files -fileset constrs_1 -norecurse \
  [file join $root_dir constraints a7ng_wide_dispatch_ooc.xdc]
set_property top $top_name [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH NG-06R-WIDE OOC ALLOC N_WAY=16 ==="
synth_design -top $top_name -part $part_name -mode out_of_context \
  -flatten_hierarchy none -directive RuntimeOptimized
write_checkpoint -force [file join $rpt_dir post_synth.dcp]

puts "=== IMPL NG-06R-WIDE OOC ==="
opt_design
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN: phys_opt $perr" }
route_design
write_checkpoint -force [file join $rpt_dir post_route.dcp]

report_utilization -file [file join $rpt_dir util_post_route.rpt]
report_timing_summary -delay_type min_max -max_paths 20 \
  -file [file join $rpt_dir timing_post_route.rpt]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set tns 0.0
foreach p [get_timing_paths -setup -max_paths 1000 -nworst 1 -slack_lesser_than 0] {
  set tns [expr {$tns + [get_property SLACK $p]}]
}
puts "NG06R_WIDE_WNS=$wns"
puts "NG06R_WIDE_TNS=$tns"

set fh [open [file join $rpt_dir post_route_summary.txt] w]
puts $fh "top=$top_name part=$part_name clk=100MHz N_WAY=16"
puts $fh "vehicle=a7ng_wide_alloc_ooc (compact pair-k; share XSim separate)"
puts $fh "WNS=$wns"
puts $fh "TNS=$tns"
close $fh

if {$wns < 0} {
  puts "NG06R_WIDE_TIMING_FAIL WNS=$wns"
  exit 6
}
puts "NG06R_WIDE_POSTROUTE_PASS WNS=$wns TNS=$tns"
exit 0
