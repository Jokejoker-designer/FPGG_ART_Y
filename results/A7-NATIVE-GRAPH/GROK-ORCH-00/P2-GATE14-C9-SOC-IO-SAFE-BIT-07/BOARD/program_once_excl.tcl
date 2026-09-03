# P2-GATE14-C9-SOC-IO-SAFE-BIT-07 program ONCE. Exact SHA 3A7EF204. PROGRAM=once.
# Do not regenerate bit. Do not program B0F64E6C or A0B338E0.
set bag [file normalize [file dirname [info script]]]
set parent [file normalize [file join $bag ..]]
set bitfile [file join $parent arty_a7_ng_native_v1_grok_orch_C9-SOC-IO-SAFE-BIT-07.bit]
set want_sha 3A7EF2044CD92730F048032ABF9E9CC914461EE7CE767745089CD082CC31A00B
set refuse_b0 B0F64E6C37F6BDB428FAB18CD6EEDD191C389AC3EE9FFB4D23B641B5D289A0A1
set refuse_a0 A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B
set want_jtag 210319BE776EA
set token [file join $bag HUMAN_PROGRAM_TOKEN.txt]
set lock [file join $bag PROGRAMMED_ONCE.txt]
set logp [file join $bag PROGRAM_RECORD.txt]

if {![string match "*P2-GATE14-C9-SOC-IO-SAFE-BIT-07*" $parent]} {
  puts stderr "REFUSE bag"; exit 3
}
if {[file exists $lock]} { puts stderr "REFUSE already programmed once"; exit 3 }
if {![file exists $token]} { puts stderr "REFUSE missing token"; exit 3 }
if {![file exists $bitfile]} { puts stderr "REFUSE missing bit"; exit 3 }

set tf [open $token r]; set ttxt [read $tf]; close $tf
if {![string match "*HUMAN_PROGRAM_TOKEN*" $ttxt]} { puts stderr "REFUSE token marker"; exit 3 }
if {![string match "*authorize_program=yes*" $ttxt]} { puts stderr "REFUSE authorize"; exit 3 }
if {![string match "*$want_sha*" [string toupper $ttxt]]} { puts stderr "REFUSE token SHA"; exit 3 }
if {[string match "*$refuse_b0*" [string toupper $ttxt]]} { puts stderr "REFUSE B0F64E6C in token"; exit 3 }
if {[string match "*$refuse_a0*" [string toupper $ttxt]]} { puts stderr "REFUSE A0B338E0 in token"; exit 3 }

set bit_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]]
if {$bit_sha ne $want_sha} { puts stderr "REFUSE SHA $bit_sha want $want_sha"; exit 3 }
if {$bit_sha eq $refuse_b0} { puts stderr "REFUSE B0F64E6C"; exit 3 }
if {$bit_sha eq $refuse_a0} { puts stderr "REFUSE A0B338E0"; exit 3 }

set lf [open $logp w]
puts $lf "PROGRAM_START [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]"
puts $lf "utc_unix=[clock seconds]"
puts $lf "bitfile=$bitfile"
puts $lf "bit_sha=$bit_sha"
flush $lf

open_hw_manager
connect_hw_server
set found 0
set tgt {}
foreach t [get_hw_targets] {
  puts "HW_TARGET $t"
  puts $lf "HW_TARGET $t"
  if {[string match "*$want_jtag*" $t]} { set found 1; set tgt $t }
}
if {!$found} { puts stderr "REFUSE JTAG"; puts $lf "JTAG_FAIL"; close $lf; exit 4 }
open_hw_target $tgt
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} { puts stderr "REFUSE PYNQ"; close $lf; exit 4 }
set a7 [get_hw_devices -quiet xc7a100t*]
if {[llength $a7] != 1} { puts stderr "REFUSE xc7a100t count"; close $lf; exit 4 }
set dev [lindex $a7 0]
current_hw_device $dev
set dname [get_property NAME $dev]
puts $lf "device=$dname part=[get_property PART $dev]"
if {$dname ne "xc7a100t_0"} { puts stderr "REFUSE device $dname"; close $lf; exit 4 }
set_property PROGRAM.FILE $bitfile [current_hw_device]
if {[catch {program_hw_devices [current_hw_device]} perr]} {
  puts $lf "PROGRAM_FAIL $perr"
  puts stderr "PROGRAM_FAIL $perr"
  close $lf
  exit 5
}
refresh_hw_device [current_hw_device]
set done_prop ""
if {[catch {set done_prop [get_property REGISTER.IR.BIT0_DONE [current_hw_device]]} de]} {
  catch {set done_prop [get_property DONE [current_hw_device]]}
}
puts $lf "PROGRAM_END [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]"
puts $lf "refresh=ok"
puts $lf "done_prop=$done_prop"
puts $lf "program_count=1"
puts $lf "target=$tgt"
close $lf
set lk [open $lock w]
puts $lk "PROGRAMMED_ONCE sha256=$bit_sha target=$tgt device=$dname"
puts $lk "TEACHER_OFF=not_claimed BOARD_PASS=not_claimed GATE14_PASS=not_claimed"
close $lk
puts "IO_SAFE_PROGRAM_DONE sha256=$bit_sha target=$tgt device=$dname program_count=1"
puts "TEACHER_OFF=not_claimed BOARD_PASS=not_claimed GATE14_PASS=not_claimed"
catch {close_hw_target}
catch {disconnect_hw_server}
exit 0
