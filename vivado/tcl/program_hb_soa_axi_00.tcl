# program_hb_soa_axi_00.tcl — JTAG program D1 SOA/AXI HB bit; serial must match 210319BE776E*
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set bitfile    [file join $root_dir results A7-NATIVE-GRAPH E2R-HB-SOA-AXI-00 arty_a7_ng_native_v1_hb_soa_axi_00.bit]
set want_jtag  210319BE776E

if {![file exists $bitfile]} {
  puts stderr "ERROR: missing $bitfile"
  exit 2
}
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
puts "HB_SOA_AXI_BIT_PROGRAM_PASS file=$bitfile target=$tgt"
exit 0
