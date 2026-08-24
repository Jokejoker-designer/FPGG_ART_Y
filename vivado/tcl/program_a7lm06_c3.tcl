# Program C3 persist-reload bit only. Does not touch C1/C2 or frozen 00-05.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set bitfile [file join $root_dir build/out/arty_a7_lm06c3.bit]
if {![file exists $bitfile]} {
    puts stderr "ERROR: missing $bitfile"
    exit 2
}
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices xc7a100t_0] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "A7_LM06_C3_PROGRAM_PASS device=[current_hw_device]"
