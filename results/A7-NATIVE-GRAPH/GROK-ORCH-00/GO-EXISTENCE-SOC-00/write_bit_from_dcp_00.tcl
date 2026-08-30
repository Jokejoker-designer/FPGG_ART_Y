# Write existence bit from already-routed DCP. PROGRAM=NO. No open_hw_manager.
# CDC clk_pll_i->core_clk uns=2 is FINDING_ONLY (u_wdma_rel_sync), same as INTEGRATE classify.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set_param general.maxThreads 8
puts "ROOT=$root"
if {![string match "*arty-a7-online-lm-grok-orch-00" $root]} {
  puts stderr "REFUSE: not grok-orch-00"
  exit 3
}

set dcp [file join $bag e2r_post_route.dcp]
set timing_rpt [file join $bag report_timing_summary.rpt]
set out_bit [file join $bag arty_a7_ng_native_v1_grok_orch_existence_00.bit]
if {![file exists $dcp]} { puts stderr "ERROR no DCP $dcp"; exit 2 }
if {![file exists $timing_rpt]} { puts stderr "ERROR no timing rpt"; exit 2 }

set tf [open $timing_rpt r]
set ttxt [read $tf]
close $tf
set wns NA; set tns NA; set whs NA; set ths NA
set seen 0
foreach line [split $ttxt "\n"] {
  if {[string match "*Design Timing Summary*" $line]} { set seen 1 }
  if {$seen && [regexp {^[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)} $line -> wns tns whs ths]} {
    break
  }
}
puts "FILE_TIMING WNS=$wns TNS=$tns WHS=$whs THS=$ths"
if {$wns eq "NA"} {
  puts stderr "STOP: cannot parse Design Timing Summary from file"
  exit 3
}
if {$wns < 0 || $tns != 0} {
  puts stderr "GATE_FAIL file WNS=$wns TNS=$tns"
  exit 5
}
if {![string match "*All user specified timing constraints are met*" $ttxt]} {
  puts stderr "GATE_FAIL timing constraints not met string missing"
  exit 5
}

set mf [open [file join $bag e2r_metrics.txt] r]
set mtxt [read $mf]
close $mf
if {![regexp {ramb36=(\d+)} $mtxt -> n36]} { set n36 999 }
if {![regexp {core_WNS=([\-\d\.]+)} $mtxt -> core_wns]} { set core_wns NA }
if {![regexp {ui_WNS=([\-\d\.]+)} $mtxt -> ui_wns]} { set ui_wns NA }
puts "FROM_METRICS ramb36=$n36 core_WNS=$core_wns ui_WNS=$ui_wns"
if {$n36 > 135} { puts stderr "GATE_FAIL BRAM36=$n36"; exit 5 }
if {$core_wns != "NA" && $core_wns < 0} { puts stderr "GATE_FAIL core_WNS"; exit 5 }
if {$ui_wns != "NA" && $ui_wns < 0} { puts stderr "GATE_FAIL ui_WNS"; exit 5 }

puts "CDC FINDING_ONLY clk_pll_i->core_clk uns=2 (u_wdma_rel_sync) not bitstream skip"
puts "=== OPEN_CHECKPOINT write_bitstream PROGRAM=NO ==="
open_checkpoint $dcp
report_cdc -details -file [file join $bag report_cdc_details.rpt]
# Omit e2r_la_pmod_ja.xdc (no LiteScope). Waive ja-only NSTD-1/UCIO-1 — same as INTEGRATE exclusive builds.
if {[catch {set_property SEVERITY {Warning} [get_drc_checks NSTD-1]} w1]} { puts "WARN nstd $w1" }
if {[catch {set_property SEVERITY {Warning} [get_drc_checks UCIO-1]} w2]} { puts "WARN ucio $w2" }
write_bitstream -force $out_bit
set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
set bf [open [file join $bag BIT_SHA256.txt] w]
puts $bf $bit_sha
close $bf
puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO"
puts "GO_EXISTENCE_SOC_00_IMPL_PASS PROGRAM=NO EXISTENCE=not_claimed"
exit 0
