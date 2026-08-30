# Program PHASE2-UART-HS-BIT-00 only. Refuse leftover. JTAG 210319BE776EA.
set bag [file normalize [file dirname [info script]]]
set bitfile [file join $bag arty_a7_ng_native_v1_grok_orch_phase2_uart_hs_00.bit]
set want_jtag 210319BE776EA
set shafile [file join $bag BIT_SHA256.txt]
if {![file exists $bitfile] || ![file exists $shafile]} {
  puts stderr "REFUSE: missing bit or BIT_SHA256.txt"
  exit 2
}
set expect_sha [string toupper [string trim [read [open $shafile r]]]]
if {![string match "*PHASE2-UART-HS-BIT-00*" $bag]} {
  puts stderr "REFUSE: not PHASE2-UART-HS-BIT-00 bag"
  exit 3
}
foreach forbidden {
  LONGBOOT close664 9DC0F8DF 15B0E502 B64B2649 dgo_pulse dgo_waitbusy existence_00 grant_miss grant_soa 00517465 885DC99C 125978D3 157D6B73 h2pack EC286E9E h2nopoison minheap_00 minheap_01 439CC42D slice_opt_00 2C1D58CE
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
if {$bit_sha ne "B0F42C119A3E00D9B2F2A17957A9613F1D90F5A6DDFDAEA1A5106A0AC5DDBA37"} {
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
puts "PHASE2_UART_HS_BIT_00_PROGRAM_DONE sha256=$bit_sha target=$tgt"
puts "BOARD_PASS=not_claimed"
exit 0
