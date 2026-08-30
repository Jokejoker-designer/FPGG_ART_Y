# Independent grok-orch Vivado GUI. PROGRAM=NO. Never open_hw_manager.
set bag [file normalize [file dirname [info script]]]
set dcp [file join $bag e2r_post_route.dcp]
puts "GROK-ORCH independent GUI"
puts "DCP=$dcp"
puts "PROGRAM=NO no open_hw_manager no JTAG"
if {![file exists $dcp]} {
  puts stderr "ERROR missing DCP"
  return
}
open_checkpoint $dcp
puts "OPENED grok-orch existence DCP WNS file=+0.164 BRAM36=103"
puts "BIT already BIT_OK B64B2649... PROGRAM=NO until human says Cursor done + arm COM12"
