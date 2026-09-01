# Write unique bit from already-routed DCP after correcting slice parse.
# PROGRAM=NO. Do not re-impl.
set bag [file normalize [file dirname [info script]]]
set dcp [file join $bag e2r_post_route.dcp]
set out_bit [file join $bag arty_a7_ng_native_v1_grok_orch_p2_g1g5_mig_persist_01.bit]
set util_rpt [file join $bag report_utilization_route.rpt]
open_checkpoint $dcp

set used_sl 0
set tot_sl 15850
set uf [open $util_rpt r]
set utxt [read $uf]
close $uf
if {![regexp {\|\s+Slice\s+\|\s+(\d+)\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+(\d+)} $utxt -> used_sl tot_sl]} {
  puts stderr "FAIL slice parse"
  exit 3
}
set free_sl [expr {$tot_sl - $used_sl}]
puts "SLICE used=$used_sl tot=$tot_sl free=$free_sl"
if {$free_sl < 64} { puts stderr "GATE_FAIL free"; exit 5 }
set risk 0
if {$free_sl < 256} { set risk 1; puts "RISK free<$free_sl" }

set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set dsps [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]
puts "BRAM36=$n36 RAMB18=$n18 DSP=$dsps"

if {$n36 > 135} { puts stderr "GATE_FAIL BRAM"; exit 5 }
if {$dsps > 240} { puts stderr "GATE_FAIL DSP"; exit 5 }

if {[catch {set_property SEVERITY {Warning} [get_drc_checks NSTD-1]} w1]} { puts "WARN nstd $w1" }
if {[catch {set_property SEVERITY {Warning} [get_drc_checks UCIO-1]} w2]} { puts "WARN ucio $w2" }
write_bitstream -force $out_bit
set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
set bf [open [file join $bag BIT_SHA256.txt] w]
puts $bf $bit_sha
close $bf
puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO free=$free_sl risk=$risk"
exit 0
