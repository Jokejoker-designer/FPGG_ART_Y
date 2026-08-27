# program_e2r_wdma_sbusy_cmd_probe_00.tcl — JTAG program F1B2 bit only
# JTAG must be 210319BE776EA. Refuse second target / PYNQ.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-WDMA-SBUSY-CMD-PROBE-00 arty_a7_ng_native_v1_wdma_sbusy_cmd_probe_00.bit]
set want_jtag  210319BE776EA

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
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
puts "E2R_WDMA_SBUSY_CMD_PROBE_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
