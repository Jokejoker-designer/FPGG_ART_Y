# program_e2r_wdma_bfix_00_excl.tcl — JTAG program BFIX-00 EXCL bit only
# JTAG must be 210319BE776EA. Refuse second target / PYNQ.
# Do NOT write B2 / F1w / F1v dirs. Do NOT source resume TCLs.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-WDMA-BFIX-00-EXCL arty_a7_ng_native_v1_wdma_bfix_00_excl.bit]
set want_jtag  210319BE776EA

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
}
if {[string match "*E2R-WDMA-SBUSY-CMD-PROBE-00*" $bitfile] ||
    [string match "*E2R-UART-MGO-HB-FIX-00*" $bitfile] ||
    [string match "*E2R-WDMA-OWNER-GRANT-PROBE-00*" $bitfile]} {
  puts stderr "REFUSE: concurrent B2/F1w/F1v bit path $bitfile"
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
puts "E2R_WDMA_BFIX_00_EXCL_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
