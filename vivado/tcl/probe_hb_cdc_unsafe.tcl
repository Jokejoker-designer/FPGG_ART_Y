# Identify the 1 unsafe CDC endpoint from E2R-HB-UART-00 r1 post-route DCP.
# Run ONLY when no other Vivado is active, OR after r2 finishes if still needed.
open_checkpoint [file join [file dirname [info script]] ../../results/A7-NATIVE-GRAPH/E2R-HB-UART-00/e2r_post_route.dcp]
set out [file join [file dirname [info script]] ../../results/A7-NATIVE-GRAPH/E2R-HB-UART-00/cdc_unsafe_detail_r1.txt]
set f [open $out w]
puts $f "=== report_cdc detailed clk_pll_i -> sys_clk_pin ==="
set rpt [report_cdc -from_clock [get_clocks -quiet clk_pll_i] -to_clock [get_clocks -quiet sys_clk_pin] -return_string -details]
puts $f $rpt
puts $f ""
puts $f "=== get_cdc_unsafe / timing paths (sample) ==="
foreach p [get_timing_paths -quiet -from [get_clocks clk_pll_i] -to [get_clocks sys_clk_pin] -max_paths 20 -nworst 1] {
  puts $f "slack=[get_property SLACK $p] start=[get_property STARTPOINT_PIN $p] end=[get_property ENDPOINT_PIN $p]"
}
# Enumerate cells matching HB sync names if present in this (r1) checkpoint
foreach c [get_cells -quiet -hierarchical -filter {NAME =~ *u_hb_sync* || NAME =~ *u_wmem_sync* || NAME =~ *u_led_sync* || NAME =~ *u_lm_sync* || NAME =~ *core_live*}] {
  puts $f "CELL $c REF=[get_property REF_NAME $c]"
}
close $f
puts "WROTE $out"
exit 0
