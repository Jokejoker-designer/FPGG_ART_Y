# Re-route E2R-CLOCK-CDC-00 from post-synth with updated async clock groups
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-CLOCK-CDC-00]
set dcp [file join $outdir e2r_post_synth.dcp]
if {![file exists $dcp]} {
  puts stderr "ERROR: missing $dcp — run full build first"
  exit 2
}
open_checkpoint $dcp
source [file join $root vivado tcl e2r_core_clk_constraints.tcl]
e2r_apply_core_clk_constraints
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN phys_opt $perr" }
route_design
if {[catch {phys_opt_design -directive Explore} perr2]} { puts "WARN phys_opt2 $perr2" }
report_timing_summary -delay_type min_max -max_paths 20 -file [file join $outdir report_timing_summary.rpt]
report_utilization -file [file join $outdir report_utilization_route.rpt]
report_clocks -file [file join $outdir report_clocks_route.rpt]
report_clock_interaction -delay_type min_max -file [file join $outdir report_clock_interaction.rpt]
report_cdc -file [file join $outdir report_cdc.rpt]
write_checkpoint -force [file join $outdir e2r_post_route.dcp]

set tsum [report_timing_summary -return_string -no_header -no_detailed_paths]
set wns NA; set tns NA; set whs NA; set ths NA
if {[regexp {WNS\(ns\)\s+TNS\(ns\)\s+WHS\(ns\)\s+THS\(ns\)\s*\n\s*([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)} $tsum -> _wns _tns _whs _ths]} {
  set wns $_wns; set tns $_tns; set whs $_whs; set ths $_ths
}

proc e2r_domain_timing {clk_obj} {
  if {[llength $clk_obj] == 0} { return [list NA NA] }
  set tsum [report_timing_summary -of_objects $clk_obj -delay_type max -return_string -no_header -no_detailed_paths]
  set wns NA
  set tns NA
  if {[regexp {WNS\(ns\)\s+TNS\(ns\)[^\n]*\n\s*([\-\d\.]+)\s+([\-\d\.]+)} $tsum -> _wns _tns]} {
    set wns $_wns
    set tns $_tns
  }
  return [list $wns $tns]
}

set core_c [get_clocks -quiet core_clk]
if {[llength $core_c] == 0} { set core_c [get_clocks -quiet core_raw] }
set ui_c [get_clocks -quiet clk_pll_i]
lassign [e2r_domain_timing $core_c] core_wns core_tns
lassign [e2r_domain_timing $ui_c] ui_wns ui_tns

set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set unsafe_cdc 0
set cdc_rpt [file join $outdir report_cdc.rpt]
if {[file exists $cdc_rpt]} {
  set cf [open $cdc_rpt r]; set ct [read $cf]; close $cf
  foreach line [split $ct "\n"] {
    if {![regexp {^\s*(Critical|Warning|Info)\s} $line]} { continue }
    if {[regexp {\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$} $line -> ep safe uns unk nar]} {
      incr unsafe_cdc $uns
    }
  }
}

set gate_pass 1
if {$n36 > 135} { puts stderr "GATE_FAIL BRAM=$n36"; set gate_pass 0 }
if {$unsafe_cdc != 0} { puts stderr "GATE_FAIL unsafe_cdc=$unsafe_cdc"; set gate_pass 0 }
if {$core_wns != "NA" && $core_wns < 0} { puts stderr "GATE_FAIL core WNS=$core_wns"; set gate_pass 0 }
if {$core_tns != "NA" && $core_tns != 0} { puts stderr "GATE_FAIL core TNS=$core_tns"; set gate_pass 0 }
if {$ui_wns != "NA" && $ui_wns < 0} { puts stderr "GATE_FAIL ui WNS=$ui_wns"; set gate_pass 0 }
if {$ui_tns != "NA" && $ui_tns != 0} { puts stderr "GATE_FAIL ui TNS=$ui_tns"; set gate_pass 0 }

set mf [open [file join $outdir e2r_metrics.txt] w]
puts $mf "ramb36=$n36 WNS=$wns TNS=$tns WHS=$whs THS=$ths"
puts $mf "core_WNS=$core_wns core_TNS=$core_tns ui_WNS=$ui_wns ui_TNS=$ui_tns"
puts $mf "unsafe_cdc=$unsafe_cdc gate_pass=$gate_pass"
close $mf
puts "E2R_METRICS ramb36=$n36 WNS=$wns core_WNS=$core_wns ui_WNS=$ui_wns unsafe_cdc=$unsafe_cdc gate_pass=$gate_pass"
if {!$gate_pass} { exit 5 }
exit 0
