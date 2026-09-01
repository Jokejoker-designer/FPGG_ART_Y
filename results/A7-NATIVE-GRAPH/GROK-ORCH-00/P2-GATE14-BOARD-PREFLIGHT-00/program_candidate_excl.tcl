# P2-GATE14-BOARD-PREFLIGHT-00 prepared exclusive program. PROGRAM=NO unless
# a human named token file cites this exact bit SHA. This preflight does not
# run this script.
set bag [file normalize [file dirname [info script]]]
set cand_bag [file normalize [file join $bag .. P2-WDMA-RELEASE-CDC-AUDIT-03]]
set bitfile [file join $cand_bag arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit]
set want_sha 6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
set want_jtag 210319BE776EA
set token [file join $bag HUMAN_PROGRAM_TOKEN.txt]
if {![string match "*P2-GATE14-BOARD-PREFLIGHT-00*" $bag]} {
  puts stderr "REFUSE bag"
  exit 3
}
if {![file exists $token]} {
  puts stderr "REFUSE missing HUMAN_PROGRAM_TOKEN.txt — preflight is PROGRAM=NO"
  exit 3
}
set tf [open $token r]
set ttxt [read $tf]
close $tf
if {![string match "*HUMAN_PROGRAM_TOKEN*" $ttxt]} {
  puts stderr "REFUSE token missing HUMAN_PROGRAM_TOKEN"
  exit 3
}
if {![string match "*authorize_program=yes*" $ttxt]} {
  puts stderr "REFUSE token not authorize_program=yes"
  exit 3
}
if {![string match "*$want_sha*" [string toupper $ttxt]]} {
  puts stderr "REFUSE token bit SHA mismatch"
  exit 3
}
foreach forbidden {D5B725CF F06C6E84 2E18B144 A1D098A5 582F9E47 mailbox_00 439CC42D B0F42C11 slice_opt 5C130884 76FDB53F 30CB1371 9DC0F8DF pred=664 29D230FC} {
  if {[string match "*$forbidden*" [string tolower $bitfile]]} {
    puts stderr "REFUSE leftover $forbidden"
    exit 3
  }
}
set bit_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]]
if {$bit_sha ne $want_sha} {
  puts stderr "REFUSE SHA $bit_sha want $want_sha"
  exit 3
}
open_hw_manager
connect_hw_server
set found 0
set tgt {}
foreach t [get_hw_targets] {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} { puts stderr "REFUSE JTAG not $want_jtag"; exit 4 }
open_hw_target $tgt
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} { puts stderr "REFUSE PYNQ"; exit 4 }
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "GATE14_PREFLIGHT_PROGRAM_DONE sha256=$bit_sha target=$tgt"
puts "TEACHER_OFF=not_claimed BOARD_PASS=not_claimed GATE14=not_closed"
exit 0
