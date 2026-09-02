# P2-GATE14-BOARD-PROGRAM-20-R1-00 program ONCE. Token + SHA locked.
set bag [file normalize [file dirname [info script]]]
set bitfile {D:/Jetking_sem4/SEM_4/arty-a7-online-lm-grok-orch-00/results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-WDMA-RELEASE-CDC-AUDIT-03/arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit}
set want_sha 6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
set want_jtag 210319BE776EA
set token [file join $bag HUMAN_PROGRAM_TOKEN.txt]
set lock [file join $bag PROGRAMMED_ONCE.txt]
set logp [file join $bag PROGRAM_RECORD.txt]
if {![string match "*P2-GATE14-BOARD-PROGRAM-20-R1-00*" $bag]} {
  puts stderr "REFUSE bag"; exit 3
}
if {[file exists $lock]} {
  puts stderr "REFUSE already programmed once"; exit 3
}
if {![file exists $token]} { puts stderr "REFUSE missing token"; exit 3 }
set tf [open $token r]; set ttxt [read $tf]; close $tf
if {![string match "*HUMAN_PROGRAM_TOKEN*" $ttxt]} { puts stderr "REFUSE token marker"; exit 3 }
if {![string match "*authorize_program=yes*" $ttxt]} { puts stderr "REFUSE authorize"; exit 3 }
if {![string match "*P2-GATE14-BOARD-PROGRAM-20-R1-00*" $ttxt]} { puts stderr "REFUSE gate"; exit 3 }
if {![string match "*$want_sha*" [string toupper $ttxt]]} { puts stderr "REFUSE token SHA"; exit 3 }
if {![string match "*wdma_release_cdc_audit_03.bit" [string tolower $bitfile]]} {
  puts stderr "REFUSE bit name"; exit 3
}
foreach forbidden {D5B725CF F06C6E84 2E18B144 A0219207 A1D098A5 582F9E47 mailbox_00 439CC42D B0F42C11 slice_opt 29D230FC pred=664 cofit_00 mig_persist} {
  if {[string match "*$forbidden*" [string tolower $bitfile]]} { puts stderr "REFUSE leftover $forbidden"; exit 3 }
}
set bit_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bitfile' | Select-Object -ExpandProperty Hash"]]
if {$bit_sha ne $want_sha} { puts stderr "REFUSE SHA $bit_sha"; exit 3 }
set lf [open $logp w]
puts $lf "PROGRAM_START [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]"
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
if {!$found} { puts stderr "REFUSE JTAG"; close $lf; exit 4 }
open_hw_target $tgt
if {[llength [get_hw_devices -quiet xc7z020*]] > 0} { puts stderr "REFUSE PYNQ"; close $lf; exit 4 }
set a7 [get_hw_devices -quiet xc7a100t*]
if {[llength $a7] != 1} { puts stderr "REFUSE xc7a100t count"; close $lf; exit 4 }
set dev [lindex $a7 0]
current_hw_device $dev
set dname [get_property NAME $dev]
set dpart [get_property PART $dev]
puts $lf "device=$dname part=$dpart"
if {$dname ne "xc7a100t_0"} { puts stderr "REFUSE device $dname"; close $lf; exit 4 }
set_property PROGRAM.FILE $bitfile [current_hw_device]
if {[catch {program_hw_devices [current_hw_device]} perr]} {
  puts $lf "PROGRAM_FAIL $perr"
  puts stderr "PROGRAM_FAIL $perr"
  close $lf
  exit 5
}
refresh_hw_device [current_hw_device]
puts $lf "PROGRAM_END [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]"
puts $lf "refresh=ok"
puts $lf "program_count=1"
puts $lf "target=$tgt"
close $lf
set lk [open $lock w]
puts $lk "PROGRAMMED_ONCE sha256=$bit_sha target=$tgt device=$dname"
puts $lk "TEACHER_OFF=not_claimed BOARD_PASS=not_claimed GATE14_PASS=not_claimed"
close $lk
puts "GATE14_R1_PROGRAM_DONE sha256=$bit_sha target=$tgt device=$dname program_count=1"
puts "TEACHER_OFF=not_claimed BOARD_PASS=not_claimed GATE14_PASS=not_claimed"
exit 0
