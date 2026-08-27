# Dump CDC details from post-route DCP for E2R fix loop
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-CLOCK-CDC-00]
open_checkpoint [file join $outdir e2r_post_route.dcp]
report_cdc -details -file [file join $outdir report_cdc_details_r2c.rpt]
# Also dump clocks and domain timing via filter (no -of_objects)
set tsum [report_timing_summary -return_string -no_header -no_detailed_paths]
set mf [open [file join $outdir e2r_timing_parse_r2c.txt] w]
puts $mf $tsum
close $mf
# Intra-clock path groups
foreach clk {core_clk core_raw clk_pll_i} {
  set c [get_clocks -quiet $clk]
  if {[llength $c] == 0} { continue }
  set paths [get_timing_paths -quiet -from $c -to $c -max_paths 1 -nworst 1 -setup]
  if {[llength $paths] > 0} {
    set slack [get_property SLACK $paths]
    puts "INTRA $clk WNS=$slack"
  } else {
    puts "INTRA $clk NO_PATHS"
  }
}
set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
puts "RAMB36=$n36"
exit 0
