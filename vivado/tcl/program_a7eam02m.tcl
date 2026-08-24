# Program EAM-02M only. Does not touch LM or frozen 01R bit files on disk.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set bitfile [file join $root_dir build/out/arty_a7_eam02m.bit]
if {![file exists $bitfile]} {
    puts stderr "ERROR: missing $bitfile"
    exit 2
}
if {[string match *arty_a7_lm* [file tail $bitfile]]} {
    puts stderr "REFUSE: refusing to program an LM-named path as EAM"
    exit 3
}
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices xc7a100t_0] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "A7_EAM02M_PROGRAM_PASS device=[current_hw_device] file=$bitfile"
