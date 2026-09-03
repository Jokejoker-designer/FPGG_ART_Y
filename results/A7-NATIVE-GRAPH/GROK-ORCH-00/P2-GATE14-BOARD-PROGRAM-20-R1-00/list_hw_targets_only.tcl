# List JTAG only. Never PROGRAM.FILE / program_hw_devices.
set bag [file normalize [file dirname [info script]]]
set want_jtag 210319BE776EA
set out [file join $bag JTAG_ENUM.txt]
set fh [open $out w]
puts $fh "gate=P2-GATE14-BOARD-PROGRAM-20-R1-00"
puts $fh "PROGRAM=NO_LIST_ONLY"
puts $fh "want_jtag=$want_jtag"
if {![string match "*P2-GATE14-BOARD-PROGRAM-20-R1-00*" $bag]} {
  puts stderr "REFUSE bag"; close $fh; exit 3
}
open_hw_manager
if {[catch {connect_hw_server} cerr]} {
  puts $fh "CONNECT_FAIL $cerr"; close $fh; exit 4
}
set tgts [get_hw_targets -quiet]
puts $fh "n_targets=[llength $tgts]"
set found 0
set tgt {}
foreach t $tgts {
  puts $fh "target=$t"
  puts "JTAG_TARGET $t"
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
puts $fh "want_found=$found"
if {!$found} {
  puts $fh "JTAG_ABSENT"
  puts stderr "JTAG_ABSENT"
  catch {disconnect_hw_server}
  close $fh
  exit 5
}
if {[catch {open_hw_target $tgt} oerr]} {
  puts $fh "OPEN_TARGET_FAIL $oerr"; catch {disconnect_hw_server}; close $fh; exit 6
}
set a7 [get_hw_devices -quiet xc7a100t*]
set zynq [get_hw_devices -quiet xc7z020*]
puts $fh "xc7a100t_count=[llength $a7]"
puts $fh "xc7z020_count=[llength $zynq]"
foreach d [get_hw_devices -quiet] {
  puts $fh "device name=[get_property NAME $d] part=[get_property PART $d]"
  puts "JTAG_DEVICE name=[get_property NAME $d] part=[get_property PART $d]"
}
if {[llength $zynq] > 0} { puts $fh "REFUSE_PYNQ"; catch {close_hw_target}; catch {disconnect_hw_server}; close $fh; exit 7 }
if {[llength $a7] != 1} { puts $fh "A7_COUNT_BAD"; catch {close_hw_target}; catch {disconnect_hw_server}; close $fh; exit 8 }
puts $fh "JTAG_ENUM_OK target=$tgt device=[lindex $a7 0]"
puts "JTAG_ENUM_OK target=$tgt PROGRAM=NO_LIST_ONLY"
catch {close_hw_target}
catch {disconnect_hw_server}
close $fh
exit 0
