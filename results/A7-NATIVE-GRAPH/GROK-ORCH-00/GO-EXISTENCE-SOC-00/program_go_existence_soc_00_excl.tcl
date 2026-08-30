# Exclusive JTAG program of grok-orch existence bit only.
# Human 2026-08-30: Cursor done → arm COM12 then program THIS bit.
# JTAG must be 210319BE776EA. Refuse leftover LONGBOOT/two-pass/close664/frozen.
set bag [file normalize [file dirname [info script]]]
set bitfile [file join $bag arty_a7_ng_native_v1_grok_orch_existence_00.bit]
set want_jtag 210319BE776EA
set expect_sha B64B26498F960980903FD4D7CF305FD4861996EBC60307901B32F89454870F17

puts "GATE=GO-EXISTENCE-SOC-00"
puts "TOKEN=human Cursor-done + arm COM12 (research/native-ai-v1-grok-orch-00)"
if {![file exists $bitfile]} {
  puts stderr "REFUSE: missing bit $bitfile"
  exit 2
}
if {![string match "*GO-EXISTENCE-SOC-00*" $bitfile] ||
    ![string match "*arty_a7_ng_native_v1_grok_orch_existence_00.bit" $bitfile]} {
  puts stderr "REFUSE: not grok-orch existence bag bit $bitfile"
  exit 3
}
foreach forbidden {
  E2R-UART-HOLD-LONGBOOT E2R-EMB-TWO-PASS close664 LONGBOOT
  9DC0F8DF 15B0E502 9C1F4565 owner_fence_integrate
  arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e arty_a7_lm06
} {
  if {[string match "*$forbidden*" $bitfile]} {
    puts stderr "REFUSE: leftover/frozen path $bitfile"
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
if {[llength $targets] > 1} {
  puts stderr "REFUSE: more than one JTAG target: $targets"
  exit 4
}
set found 0
foreach t $targets {
  if {[string match "*PYNQ*" $t] || [string match "*1234-TUL*" $t] || [string match "*xc7z020*" $t]} {
    puts stderr "REFUSE: PYNQ/Z2 out of scope: $t"
    exit 4
  }
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} {
  puts stderr "REFUSE: JTAG matching $want_jtag not found (got $targets)"
  exit 4
}
open_hw_target $tgt
set zynq_devs [get_hw_devices -quiet xc7z020*]
if {[llength $zynq_devs] > 0} {
  puts stderr "REFUSE: PYNQ/Z2 device present: $zynq_devs"
  exit 4
}
set arty_devs [get_hw_devices xc7a100t*]
if {[llength $arty_devs] < 1} {
  puts stderr "REFUSE: no xc7a100t on $tgt"
  exit 4
}
current_hw_device [lindex $arty_devs 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "GO_EXISTENCE_SOC_00_PROGRAM_DONE file=$bitfile sha256=$bit_sha target=$tgt"
puts "BOARD_PASS=not_claimed EXISTENCE=uart_pending"
exit 0
