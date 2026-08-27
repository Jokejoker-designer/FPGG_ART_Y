# E2R-UART-MGO-HB-FIX-00 F1w RESUME from post-synth DCP (place was killed mid-run)
set root [file normalize [file join [file dirname [info script]] ../..]]
set_param general.maxThreads 8
puts "VIVADO maxThreads=[get_param general.maxThreads]"
set outdir [file join $root results A7-NATIVE-GRAPH E2R-UART-MGO-HB-FIX-00]
set dcp [file join $outdir e2r_post_synth.dcp]
if {![file exists $dcp]} {
  puts stderr "ERROR: missing $dcp"
  exit 2
}

open_checkpoint $dcp
puts "=== IMPLEMENT E2R-UART-MGO-HB-FIX-00 (RESUME) ==="
source [file join $root vivado tcl e2r_core_clk_constraints.tcl]
e2r_apply_core_clk_constraints
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN phys_opt $perr" }
route_design
if {[catch {phys_opt_design -directive Explore} perr2]} { puts "WARN phys_opt2 $perr2" }

report_timing_summary -delay_type min_max -max_paths 20 -file [file join $outdir report_timing_summary.rpt]
report_utilization -hierarchical -file [file join $outdir report_utilization_route_hier.rpt]
report_utilization -file [file join $outdir report_utilization_route.rpt]
report_clocks -file [file join $outdir report_clocks_route.rpt]
report_clock_interaction -delay_type min_max -file [file join $outdir report_clock_interaction.rpt]
report_cdc -file [file join $outdir report_cdc.rpt]
report_route_status -file [file join $outdir report_route_status.rpt]
write_checkpoint -force [file join $outdir e2r_post_route.dcp]

proc e2r_domain_timing {clk_name} {
  set clk_obj [get_clocks -quiet $clk_name]
  if {[llength $clk_obj] == 0} { return [list NA NA] }
  set paths [get_timing_paths -quiet -from $clk_obj -to $clk_obj -max_paths 1 -nworst 1 -setup]
  if {[llength $paths] == 0} { return [list NA NA] }
  set wns [get_property SLACK $paths]
  set tns 0
  if {$wns < 0} {
    set fail [get_timing_paths -quiet -from $clk_obj -to $clk_obj -max_paths 1000 -nworst 1 -setup -slack_lesser_than 0]
    foreach p $fail {
      set tns [expr {$tns + [get_property SLACK $p]}]
    }
  }
  return [list $wns $tns]
}

proc e2r_parse_unsafe_cdc {cdc_text} {
  set unsafe 0
  set mig_benign 0
  foreach line [split $cdc_text "\n"] {
    if {![regexp {^\s*(Critical|Warning|Info)\s+(\S+)\s+(\S+)} $line -> sev src dst]} { continue }
    if {![regexp {\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$} $line -> ep safe uns unk nar]} { continue }
    if {$uns == 0} { continue }
    if {[string match "*False Path*" $line] && $src eq "c166_raw" &&
        ($dst eq "clk_div2_bufg_in" || $dst eq "clk_pll_i" || $dst eq "mmcm_ps_clk_bufg_in")} {
      incr mig_benign $uns
      continue
    }
    incr unsafe $uns
  }
  puts "CDC user_unsafe=$unsafe mig_benign_falsepath=$mig_benign"
  return $unsafe
}

set tsum [report_timing_summary -return_string -no_header -no_detailed_paths]
set wns NA; set tns NA; set whs NA; set ths NA
if {[regexp {WNS\(ns\)\s+TNS\(ns\)\s+WHS\(ns\)\s+THS\(ns\)\s*\n\s*([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)} $tsum -> _wns _tns _whs _ths]} {
  set wns $_wns
  set tns $_tns
  set whs $_whs
  set ths $_ths
}

set core_wns NA; set core_tns NA; set ui_wns NA; set ui_tns NA
if {[llength [get_clocks -quiet core_clk]] > 0} {
  lassign [e2r_domain_timing core_clk] core_wns core_tns
} elseif {[llength [get_clocks -quiet core_raw]] > 0} {
  lassign [e2r_domain_timing core_raw] core_wns core_tns
}
if {[llength [get_clocks -quiet clk_pll_i]] > 0} {
  lassign [e2r_domain_timing clk_pll_i] ui_wns ui_tns
}

set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set dsps [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

set cdc_rpt [file join $outdir report_cdc.rpt]
set unsafe_cdc 0
if {[file exists $cdc_rpt]} {
  set cf [open $cdc_rpt r]
  set cdc_text [read $cf]
  close $cf
  set unsafe_cdc [e2r_parse_unsafe_cdc $cdc_text]
  puts "CDC unsafe=$unsafe_cdc"
}

set gate_pass 1
if {$n36 > 135} { puts stderr "GATE_FAIL BRAM36=$n36"; set gate_pass 0 }
if {$unsafe_cdc != 0} { puts stderr "GATE_FAIL unsafe_cdc=$unsafe_cdc"; set gate_pass 0 }
if {$core_wns != "NA" && $core_wns < 0} { puts stderr "GATE_FAIL core WNS=$core_wns"; set gate_pass 0 }
if {$core_tns != "NA" && $core_tns != 0} { puts stderr "GATE_FAIL core TNS=$core_tns"; set gate_pass 0 }
if {$ui_wns != "NA" && $ui_wns < 0} { puts stderr "GATE_FAIL ui WNS=$ui_wns"; set gate_pass 0 }
if {$ui_tns != "NA" && $ui_tns != 0} { puts stderr "GATE_FAIL ui TNS=$ui_tns"; set gate_pass 0 }

set mf [open [file join $outdir e2r_metrics.txt] w]
puts $mf "ramb36=$n36 ramb18=$n18 dsps=$dsps"
puts $mf "WNS=$wns TNS=$tns WHS=$whs THS=$ths"
puts $mf "core_WNS=$core_wns core_TNS=$core_tns ui_WNS=$ui_wns ui_TNS=$ui_tns"
puts $mf "unsafe_cdc=$unsafe_cdc gate_pass=$gate_pass"
close $mf

puts "E2R_METRICS ramb36=$n36 WNS=$wns TNS=$tns core_WNS=$core_wns ui_WNS=$ui_wns unsafe_cdc=$unsafe_cdc gate_pass=$gate_pass"

set bitdir [file join $root build out]
file mkdir $bitdir
set out_bit [file join $bitdir arty_a7_ng_native_v1_uart_mgo_hb_fix_00.bit]
if {$gate_pass} {
  puts "=== WRITE_BITSTREAM E2R-UART-MGO-HB-FIX-00 ==="
  write_bitstream -force $out_bit
  file copy -force $out_bit [file join $outdir arty_a7_ng_native_v1_uart_mgo_hb_fix_00.bit]
  set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
  set bf [open [file join $outdir BIT_SHA256.txt] w]
  puts $bf $bit_sha
  close $bf
  puts "BIT_OK path=$out_bit sha256=$bit_sha"
} else {
  puts "SKIP_BITSTREAM gate_pass=0"
  exit 5
}
exit 0
