# program_e2r_uart_mgo_hb_fix_00_excl.tcl — JTAG program F1w EXCL bit only
# Refuse concurrent-dir bits. JTAG must be 210319BE776EA.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-UART-MGO-HB-FIX-00-EXCL arty_a7_ng_native_v1_uart_mgo_hb_fix_00_excl.bit]
set want_jtag  210319BE776EA

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
}
if {[string match "*E2R-UART-MGO-HB-FIX-00/*" $bitfile] ||
    [string match "*e2r_uart_mgo_hb_fix_00_f1w/*" $bitfile]} {
  puts stderr "REFUSE: concurrent-dir bit path $bitfile"
  exit 3
}

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "HW_TARGETS=$targets"
if {[llength $targets] > 1} {
  puts stderr "REFUSE: more than one JTAG target: $targets"
  exit 4
}
set found 0
foreach t $targets {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} {
  puts stderr "REFUSE: JTAG matching $want_jtag not found (got $targets)"
  exit 4
}
open_hw_target $tgt
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "UART_MGO_HB_FIX_EXCL_BIT_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
