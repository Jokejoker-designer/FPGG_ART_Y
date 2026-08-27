set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-UART-MGO-HB-FIX-00-EXCL arty_a7_ng_native_v1_uart_mgo_hb_fix_00_excl.bit]
set want_jtag  210319BE776EA
if {![file exists $bitfile]} { puts stderr "ERROR: missing $bitfile"; exit 2 }
open_hw_manager
# Connect to already-running hw_server (do not relaunch)
if {[catch {connect_hw_server -url localhost:3121} err]} {
  puts stderr "connect_hw_server failed: $err"
  # Fallback: kill conflict by connecting with auto
  if {[catch {connect_hw_server} err2]} { puts stderr "FATAL $err2"; exit 5 }
}
set targets [get_hw_targets]
puts "HW_TARGETS=$targets"
set found 0
foreach t $targets {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} { puts stderr "REFUSE: JTAG $want_jtag not in $targets"; exit 4 }
if {[llength $targets] > 1} {
  # Prefer Arty only
  puts "NOTE: multiple targets; selecting $tgt"
}
open_hw_target $tgt
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "UART_MGO_HB_FIX_EXCL_BIT_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
