# Archive high-fanout from existing U2 post-route DCP. No impl. No bitstream.
set bag [file normalize [file dirname [info script]]]
set dcp [file join $bag e2r_post_route.dcp]
if {![file exists $dcp]} {
  puts stderr "REFUSE: missing $dcp"
  exit 2
}
open_checkpoint $dcp
report_high_fanout_nets -max_nets 50 -file [file join $bag report_high_fanout.rpt]
close_design
puts "U2_HIGH_FANOUT_ARCHIVED"
exit 0
