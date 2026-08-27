# program_e2r_tile_miss_probe_00.tcl — JTAG program F1o TILE-MISS-PROBE bit; serial must match 210319BE776E*
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-TILE-MISS-PROBE-00 arty_a7_ng_native_v1_tile_miss_probe_00.bit]
set want_jtag  210319BE776E

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
}
open_hw_manager
connect_hw_server
set found 0
foreach t [get_hw_targets] {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} {
  puts stderr "REFUSE: JTAG matching $want_jtag not found"
  exit 4
}
open_hw_target $tgt
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "TILE_MISS_PROBE_BIT_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
