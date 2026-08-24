set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set bitfile [file join $root_dir build/out/arty_a7_eam03e_a03.bit]
if {![file exists $bitfile]} {
    puts stderr "ERROR: missing $bitfile"
    exit 2
}
foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE"
        exit 3
    }
}
open_hw_manager
connect_hw_server
# pin the Arty; refuse if the expected serial is not the one enumerated
set want 210319BE776EA
set found 0
foreach t [get_hw_targets] {
    if {[string match *$want* $t]} { set found 1; set tgt $t }
}
if {!$found} {
    puts stderr "REFUSE: JTAG target $want not found; will not program an unknown board"
    exit 4
}
open_hw_target $tgt
current_hw_device [lindex [get_hw_devices xc7a100t_0] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "A7_EAM03E_A03_PROGRAM_PASS file=$bitfile target=$tgt"
