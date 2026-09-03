# program_e2r_core_start_rst_probe_00.tcl
# One JTAG program of the unique CORE-START-RST-PROBE bit. No second program.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-CORE-START-RST-PROBE-00 arty_a7_ng_native_v1_core_start_rst_probe_00.bit]
set shafile    [file join $root_dir results A7-NATIVE-GRAPH E2R-CORE-START-RST-PROBE-00 BIT_SHA256.txt]
set want_jtag  210319BE776E

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile — refuse to program any other bit"
  exit 2
}
if {![file exists $shafile]} {
  puts stderr "ERROR: missing BIT_SHA256.txt — refuse unknown bit"
  exit 2
}

set want_sha [string trim [read [open $shafile r]]]
set got_sha  [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]
if {[string compare -nocase $want_sha $got_sha] != 0} {
  puts stderr "REFUSE: bit SHA $got_sha != recorded $want_sha"
  exit 3
}

puts "PROGRAM_T0_UNIX=[clock seconds]"
open_hw_manager
connect_hw_server
set found 0
foreach t [get_hw_targets] {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} {
  puts stderr "REFUSE: JTAG matching $want_jtag not found"
  exit 4
}
open_hw_target $tgt
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
set done_unix [clock seconds]
puts "DONE_UNIX=$done_unix"
puts "CORE_START_RST_PROBE_BIT_PROGRAM_PASS file=$bitfile sha256=$got_sha target=$tgt"
# Explicitly do not program a second time.
exit 0
