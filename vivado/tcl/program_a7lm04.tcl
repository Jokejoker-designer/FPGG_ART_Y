set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set bit [file join $root_dir build out arty_a7_lm04.bit]
if {![file exists $bit]} { puts stderr "missing $bit"; exit 2 }
open_hw_manager
connect_hw_server
open_hw_target
set xc7 [get_hw_devices -quiet xc7a100t_0]
if {$xc7 eq ""} { set xc7 [lindex [get_hw_devices] 0] }
current_hw_device $xc7
refresh_hw_device -update_hw_probes false $xc7
set_property PROGRAM.FILE $bit $xc7
program_hw_devices $xc7
puts "A7_LM04_PROGRAM_PASS device=$xc7"
