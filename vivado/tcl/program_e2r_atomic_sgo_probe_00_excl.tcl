# program_e2r_atomic_sgo_probe_00_excl.tcl — JTAG program SGO ATOM probe bit only
# JTAG must be 210319BE776EA. Refuse second target / PYNQ.
# Do NOT write F1x / DGR / B-FIX / B2 / F1w / F1v / Grok R6 / frozen LM-06.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-ATOMIC-SGO-PROBE-00 arty_a7_ng_native_v1_atomic_sgo_probe_00.bit]
set want_jtag  210319BE776EA

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
}
if {[string match "*E2R-ATOMIC-DGR-PROBE-00*" $bitfile] ||
    [string match "*E2R-WDMA-BFIX-00*" $bitfile] ||
    [string match "*E2R-WDMA-SBUSY-CMD-PROBE-00*" $bitfile] ||
    [string match "*E2R-UART-MGO-HB-FIX-00*" $bitfile] ||
    [string match "*E2R-WDMA-OWNER-GRANT-PROBE-00*" $bitfile] ||
    [string match "*TINYGPT-SOC*" $bitfile] ||
    [string match "*lm06*" $bitfile]} {
  puts stderr "REFUSE: foreign/frozen/F1x bit path $bitfile"
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
puts "E2R_ATOMIC_SGO_PROBE_00_EXCL_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
