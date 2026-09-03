# P2-GATE14-BOARD-PREFLIGHT-00 — list JTAG only. PROGRAM=NO.
# Never set PROGRAM.FILE. Never program_hw_devices. Never open UART.
set bag [file normalize [file dirname [info script]]]
set want_jtag 210319BE776EA
set out [file join $bag JTAG_ENUM.txt]
set fh [open $out w]
puts $fh "gate=P2-GATE14-BOARD-PREFLIGHT-00"
puts $fh "PROGRAM=NO"
puts $fh "want_jtag=$want_jtag"
if {![string match "*P2-GATE14-BOARD-PREFLIGHT-00*" $bag]} {
  puts stderr "REFUSE bag"
  close $fh
  exit 3
}
open_hw_manager
if {[catch {connect_hw_server} cerr]} {
  puts $fh "CONNECT_FAIL $cerr"
  puts stderr "CONNECT_FAIL $cerr"
  close $fh
  exit 4
}
puts $fh "hw_server=connected"
set tgts [get_hw_targets -quiet]
puts $fh "n_targets=[llength $tgts]"
set found 0
set tgt {}
foreach t $tgts {
  puts $fh "target=$t"
  puts "JTAG_TARGET $t"
  if {[string match "*$want_jtag*" $t]} {
    set found 1
    set tgt $t
  }
  if {[string match "*1234-TUL*" $t] || [string match "*xc7z020*" $t]} {
    puts $fh "PYNQ_SEEN $t"
  }
}
puts $fh "want_found=$found"
if {!$found} {
  puts $fh "JTAG_ABSENT"
  puts stderr "JTAG_ABSENT want=$want_jtag"
  catch {disconnect_hw_server}
  close $fh
  exit 5
}
if {[catch {open_hw_target $tgt} oerr]} {
  puts $fh "OPEN_TARGET_FAIL $oerr"
  puts stderr "OPEN_TARGET_FAIL $oerr"
  catch {disconnect_hw_server}
  close $fh
  exit 6
}
set devs [get_hw_devices -quiet]
puts $fh "n_devices=[llength $devs]"
foreach d $devs {
  set name [get_property NAME $d]
  set part [get_property PART $d]
  puts $fh "device name=$name part=$part"
  puts "JTAG_DEVICE name=$name part=$part"
}
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} {
  puts $fh "REFUSE_PYNQ"
  puts stderr "REFUSE PYNQ"
  catch {close_hw_target}
  catch {disconnect_hw_server}
  close $fh
  exit 7
}
set a7 [get_hw_devices -quiet xc7a100t*]
puts $fh "xc7a100t_count=[llength $a7]"
if {[llength $a7] == 0} {
  puts $fh "A7_DEVICE_ABSENT"
  catch {close_hw_target}
  catch {disconnect_hw_server}
  close $fh
  exit 8
}
puts $fh "JTAG_ENUM_OK target=$tgt device=[lindex $a7 0]"
puts "JTAG_ENUM_OK target=$tgt PROGRAM=NO"
catch {close_hw_target}
catch {disconnect_hw_server}
close $fh
exit 0
