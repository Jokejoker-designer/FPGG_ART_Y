# Exclusive JTAG program of grok-orch D_GO-pulse bit only.
# Human: Cursor returned COM12. Do not program leftover/old existence B64B2649.
set bag [file normalize [file dirname [info script]]]
set bitfile [file join $bag arty_a7_ng_native_v1_grok_orch_dgo_pulse_00.bit]
set want_jtag 210319BE776EA
set expect_sha 125978D315B33E2F3E476919886B3DCA9868814F1F04E9C07D31D007A6B86072

puts "GATE=GO-DGO-PULSE-SOC-00"
if {![file exists $bitfile]} {
  puts stderr "REFUSE: missing bit $bitfile"
  exit 2
}
if {![string match "*GO-DGO-PULSE-SOC-00*" $bitfile] ||
    ![string match "*dgo_pulse_00.bit" $bitfile]} {
  puts stderr "REFUSE: not dgo-pulse bag bit $bitfile"
  exit 3
}
foreach forbidden {
  E2R-UART-HOLD-LONGBOOT E2R-EMB-TWO-PASS close664 LONGBOOT
  9DC0F8DF 15B0E502 9C1F4565 B64B2649 existence_00
  arty_a7_lm arty_a7_eam01r arty_a7_eam02m
} {
  if {[string match "*$forbidden*" $bitfile]} {
    puts stderr "REFUSE: leftover/old path $bitfile"
    exit 3
  }
}
set bit_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]]
puts "BIT_SHA256=$bit_sha"
if {$bit_sha ne $expect_sha} {
  puts stderr "REFUSE: bit SHA drifted $bit_sha want $expect_sha"
  exit 3
}

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "HW_TARGETS=$targets"
set found 0
set tgt {}
foreach t $targets {
  if {[string match "*$want_jtag*" $t]} {
    set found 1
    set tgt $t
  }
}
if {!$found} {
  puts stderr "REFUSE: JTAG $want_jtag not found (got $targets)"
  exit 4
}
puts "SELECT_ARTY=$tgt (ignore other cables; do not open PYNQ/TUL)"
open_hw_target $tgt
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} {
  puts stderr "REFUSE: PYNQ/Z2 device present"
  exit 4
}
set arty_devs [get_hw_devices xc7a100t*]
if {[llength $arty_devs] < 1} {
  puts stderr "REFUSE: no xc7a100t"
  exit 4
}
current_hw_device [lindex $arty_devs 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "GO_DGO_PULSE_SOC_00_PROGRAM_DONE file=$bitfile sha256=$bit_sha target=$tgt"
puts "BOARD_PASS=not_claimed EXISTENCE=uart_pending"
exit 0
