set root [file normalize [file join [file dirname [info script]] ../..]]
set bit [file join $root results A7-NATIVE-GRAPH E2R-LA-PMOD-00 arty_a7_ng_native_v1_la_pmod_00.bit]
if {![file exists $bit]} {
  puts stderr "ERROR missing $bit"
  exit 2
}
open_hw_manager
connect_hw_server
open_hw_target
set xc7 [get_hw_devices -quiet xc7a100t_0]
if {$xc7 eq ""} { set xc7 [lindex [get_hw_devices] 0] }
puts "HW_DEVICES=[get_hw_devices] pick=$xc7"
current_hw_device $xc7
refresh_hw_device -update_hw_probes false $xc7
set_property PROGRAM.FILE $bit $xc7
program_hw_devices $xc7
refresh_hw_device $xc7
puts "E2R_LA_PMOD_PROGRAM_PASS device=$xc7 bit=$bit"
exit 0
