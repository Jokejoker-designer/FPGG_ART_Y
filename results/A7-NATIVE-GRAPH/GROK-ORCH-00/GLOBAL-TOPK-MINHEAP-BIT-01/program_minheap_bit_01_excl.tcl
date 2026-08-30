# Program minheap_01 only. Refuse leftover. JTAG 210319BE776EA. No PYNQ.
set bag [file normalize [file dirname [info script]]]
set bitfile [file join $bag arty_a7_ng_native_v1_grok_orch_minheap_01.bit]
set want_jtag 210319BE776EA
set shafile [file join $bag BIT_SHA256.txt]
if {![file exists $bitfile] || ![file exists $shafile]} {
  puts stderr "REFUSE: missing bit or BIT_SHA256.txt"
  exit 2
}
set expect_sha [string toupper [string trim [read [open $shafile r]]]]
if {![string match "*GLOBAL-TOPK-MINHEAP-BIT-01*" $bitfile] && ![string match "*minheap_01*" $bitfile]} {
  puts stderr "REFUSE: not MINHEAP-BIT-01 bag"
  exit 3
}
foreach forbidden {
  LONGBOOT close664 9DC0F8DF 15B0E502 B64B2649 dgo_pulse dgo_waitbusy existence_00 grant_miss grant_soa 00517465 885DC99C 125978D3 157D6B73 h2pack EC286E9E h2nopoison minheap_00
} {
  if {[string match "*$forbidden*" $bitfile]} {
    puts stderr "REFUSE leftover $bitfile"
    exit 3
  }
}
set bit_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]]
if {$bit_sha ne $expect_sha} {
  puts stderr "REFUSE SHA $bit_sha want $expect_sha"
  exit 3
}
if {$bit_sha ne "439CC42D9BA0B3780C384C47E6E7F0A886269929E3ED3667471F064A8A222A8D"} {
  puts stderr "REFUSE unexpected SHA $bit_sha"
  exit 3
}
open_hw_manager
connect_hw_server
set found 0
set tgt {}
foreach t [get_hw_targets] {
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} { puts stderr "REFUSE JTAG"; exit 4 }
open_hw_target $tgt
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} { puts stderr "REFUSE PYNQ"; exit 4 }
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "MINHEAP_BIT_01_PROGRAM_DONE sha256=$bit_sha target=$tgt"
puts "BOARD_PASS=not_claimed"
exit 0
