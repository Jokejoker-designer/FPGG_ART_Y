# program_e2r_uart_hold_longboot_00_excl.tcl — exclusive JTAG program of SDONE ATOM probe bit
# For later gate E2R-UART-HOLD-LONGBOOT-00 only. Archived this PREP gate.
# PROGRAM not executed this gate (E2R-UART-HOLD-LONGBOOT-PREP-00).
# JTAG must be 210319BE776EA. Refuse second target / PYNQ.
# Do NOT write SGO / F1x / DGR / B-FIX / B2 / F1w / F1v / Grok R6 / frozen LM-06.
# Bit path must be E2R-ATOMIC-SDONE-PROBE-00 / arty_a7_ng_native_v1_atomic_sdone_probe_00.bit
# Omit e2r_la_pmod_ja.xdc. Do not use a catch-all match.
set script_dir [file normalize [file dirname [info script]]]
set bit_name   arty_a7_ng_native_v1_atomic_sdone_probe_00.bit
set bit_from_vivado [file normalize [file join $script_dir ../.. results A7-NATIVE-GRAPH E2R-ATOMIC-SDONE-PROBE-00 $bit_name]]
set bit_from_bag    [file normalize [file join $script_dir ../ E2R-ATOMIC-SDONE-PROBE-00 $bit_name]]
if {[file exists $bit_from_vivado]} {
  set bitfile $bit_from_vivado
} elseif {[file exists $bit_from_bag]} {
  set bitfile $bit_from_bag
} else {
  puts stderr "ERROR: missing SDONE probe bit (tried $bit_from_vivado and $bit_from_bag)"
  exit 2
}
set want_jtag  210319BE776EA

if {![string match "*E2R-ATOMIC-SDONE-PROBE-00*" $bitfile] ||
    ![string match "*atomic_sdone_probe_00.bit" $bitfile]} {
  puts stderr "REFUSE: bit path is not this SDONE probe bit $bitfile"
  exit 3
}
if {[string match "*E2R-ATOMIC-SGO-PROBE-00*" $bitfile] ||
    [string match "*atomic_sgo*" $bitfile] ||
    [string match "*E2R-ATOMIC-DGR-PROBE-00*" $bitfile] ||
    [string match "*E2R-WDMA-BFIX-00*" $bitfile] ||
    [string match "*E2R-WDMA-SBUSY-CMD-PROBE-00*" $bitfile] ||
    [string match "*E2R-UART-MGO-HB-FIX-00*" $bitfile] ||
    [string match "*E2R-WDMA-OWNER-GRANT-PROBE-00*" $bitfile] ||
    [string match "*F1x*" $bitfile] ||
    [string match "*F1w*" $bitfile] ||
    [string match "*F1v*" $bitfile] ||
    [string match "*F1u*" $bitfile] ||
    [string match "*F1t*" $bitfile] ||
    [string match "*B-FIX*" $bitfile] ||
    [string match "*BFIX*" $bitfile] ||
    [string match "*R6*" $bitfile] ||
    [string match "*frozen*" $bitfile] ||
    [string match "*TINYGPT-SOC*" $bitfile] ||
    [string match "*lm06*" $bitfile]} {
  puts stderr "REFUSE: foreign/frozen/SGO/F1x/B-FIX/R6 bit path $bitfile"
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
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
puts "E2R_UART_HOLD_LONGBOOT_00_EXCL_PROGRAM_PASS LONGBOOT file=$bitfile target=$tgt PROGRAM not executed this gate"
exit 0
