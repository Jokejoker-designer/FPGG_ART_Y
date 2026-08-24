# measure_bram_consolidate.tcl
# Gate: bram_consolidate | Agent: a7-ng-memory-arch
# ONE unknown: WM phase-share of wt+act into TinyGPT-sized shared pool (132)
# collapses additive 260 → ≤135 Prefer WNS≥0, without overwriting frozen LM-06.
# Evidence class: POST_ROUTE_PROXY (consol block) + ENGINEERING_INFERENCE (co-fit).
# Not BOARD_PASS. Not HS-22 closed.

set root_dir  [file normalize [file join [file dirname [info script]] ../../..]]
set build_dir [file join $root_dir build vivado_a7ng_bram_consol]
set rpt_dir   [file join $root_dir results A7-NATIVE-GRAPH BRAM-CONSOL]
set part_name xc7a100tcsg324-1
set bitfile   [file join $rpt_dir arty_a7_ng_bram_consol.bit]

file mkdir $build_dir
file mkdir $rpt_dir

# Minimal clock constraint (board pin set for keep; timing Prefer 100 MHz)
set xdc_path [file join $build_dir bram_consol.xdc]
set xfh [open $xdc_path w]
puts $xfh {create_clock -period 10.000 -name clk100 [get_ports CLK100MHZ]}
puts $xfh {set_property PACKAGE_PIN E3 [get_ports CLK100MHZ]}
puts $xfh {set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]}
puts $xfh {set_property PACKAGE_PIN A8  [get_ports {sw[0]}]}
puts $xfh {set_property PACKAGE_PIN C11 [get_ports {sw[1]}]}
puts $xfh {set_property PACKAGE_PIN C10 [get_ports {sw[2]}]}
puts $xfh {set_property PACKAGE_PIN A10 [get_ports {sw[3]}]}
puts $xfh {set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]}
puts $xfh {set_property PACKAGE_PIN D9 [get_ports {btn[0]}]}
puts $xfh {set_property PACKAGE_PIN C9 [get_ports {btn[1]}]}
puts $xfh {set_property PACKAGE_PIN B9 [get_ports {btn[2]}]}
puts $xfh {set_property PACKAGE_PIN B8 [get_ports {btn[3]}]}
puts $xfh {set_property IOSTANDARD LVCMOS33 [get_ports {btn[*]}]}
puts $xfh {set_property PACKAGE_PIN H5  [get_ports {led[0]}]}
puts $xfh {set_property PACKAGE_PIN J5  [get_ports {led[1]}]}
puts $xfh {set_property PACKAGE_PIN T9  [get_ports {led[2]}]}
puts $xfh {set_property PACKAGE_PIN T10 [get_ports {led[3]}]}
puts $xfh {set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]}
close $xfh

create_project -force a7ng_bram_consol $build_dir -part $part_name
set_property target_language Verilog [current_project]

add_files -norecurse [list \
  [file join $root_dir rtl/native_graph/memory/a7ng_bram_consol_tile.sv] \
  [file join $root_dir rtl/native_graph/memory/a7ng_bram_consol.sv] \
  [file join $root_dir rtl/native_graph/memory/a7ng_bram_consol_top.sv]]
add_files -fileset constrs_1 -norecurse $xdc_path
set_property top a7ng_bram_consol_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top a7ng_bram_consol_top -part $part_name
opt_design
place_design
route_design

report_utilization -file [file join $rpt_dir consol_util.rpt]
report_utilization -hierarchical -file [file join $rpt_dir consol_util_hier.rpt]
report_timing_summary -file [file join $rpt_dir consol_timing.rpt]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
set tns 0.0
set ths 0.0
foreach p [get_timing_paths -max_paths 1000 -nworst 1 -setup -filter {SLACK < 0}] {
  set tns [expr {$tns + [get_property SLACK $p]}]
}
foreach p [get_timing_paths -max_paths 1000 -nworst 1 -hold -filter {SLACK < 0}] {
  set ths [expr {$ths + [get_property SLACK $p]}]
}

set r36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set r18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set bram_tiles [expr {$r36 + ($r18 / 2.0)}]
set lut [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ LUT*}]]
set ff  [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ FD*}]]
set dsp [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

puts "BRAM_CONSOL_WNS=$wns"
puts "BRAM_CONSOL_TNS=$tns"
puts "BRAM_CONSOL_WHS=$whs"
puts "BRAM_CONSOL_THS=$ths"
puts "BRAM_CONSOL_R36=$r36"
puts "BRAM_CONSOL_R18=$r18"
puts "BRAM_CONSOL_BRAM_TILES=$bram_tiles"
puts "BRAM_CONSOL_LUT=$lut"
puts "BRAM_CONSOL_FF=$ff"
puts "BRAM_CONSOL_DSP=$dsp"

# Control arithmetic (TinyGPT-SOC LIMIT archive)
set bram_ua 128
set bram_tinygpt 132
set bram_additive [expr {$bram_ua + $bram_tinygpt}]
set bram_device 135
set headroom_ua [expr {$bram_device - $bram_ua}]
set cofit_proj $bram_tiles
set headroom_after [expr {$bram_device - $cofit_proj}]
set headroom_for_tinygpt $headroom_after

puts "BRAM_CONSOL_CONTROL_UA=$bram_ua"
puts "BRAM_CONSOL_CONTROL_TINYGPT=$bram_tinygpt"
puts "BRAM_CONSOL_ADDITIVE=$bram_additive"
puts "BRAM_CONSOL_COFIT_PROJ=$cofit_proj"
puts "BRAM_CONSOL_HEADROOM_AFTER=$headroom_after"

set metrics_path [file join $rpt_dir METRICS.json]
set mf [open $metrics_path w]
puts $mf "\{"
puts $mf "  \"gate\": \"bram_consolidate\","
puts $mf "  \"agent\": \"a7-ng-memory-arch\","
puts $mf "  \"device\": \"$part_name\","
puts $mf "  \"consol_lever\": \"WM_phase_share_wt_and_act\","
puts $mf "  \"evidence_class\": \"POST_ROUTE_PROXY\","
puts $mf "  \"measured\": \{"
puts $mf "    \"bram_tiles\": $bram_tiles,"
puts $mf "    \"ramb36\": $r36,"
puts $mf "    \"ramb18\": $r18,"
puts $mf "    \"lut_cells\": $lut,"
puts $mf "    \"ff_cells\": $ff,"
puts $mf "    \"dsp\": $dsp,"
puts $mf "    \"wns_ns\": $wns,"
puts $mf "    \"tns_ns\": $tns,"
puts $mf "    \"whs_ns\": $whs,"
puts $mf "    \"ths_ns\": $ths"
puts $mf "  \},"
puts $mf "  \"control\": \{"
puts $mf "    \"ua_bram\": $bram_ua,"
puts $mf "    \"tinygpt_bram\": $bram_tinygpt,"
puts $mf "    \"additive_bram\": $bram_additive,"
puts $mf "    \"ua_headroom\": $headroom_ua,"
puts $mf "    \"device_bram\": $bram_device"
puts $mf "  \},"
puts $mf "  \"projection\": \{"
puts $mf "    \"cofit_bram\": $cofit_proj,"
puts $mf "    \"headroom_after\": $headroom_after,"
puts $mf "    \"formula\": \"shared_pool=max(UA128,TinyGPT132)=132 (not additive 260)\""
puts $mf "  \}"
puts $mf "\}"
close $mf

# Verdict
set ok_pack  [expr {$r36 >= 120}]
set ok_dev   [expr {$bram_tiles <= 135}]
set ok_prefer [expr {$bram_tiles <= 130}]
set ok_wns   [expr {$wns >= 0.0}]
set ok_tns   [expr {abs($tns) < 1e-9}]
set ok_cofit [expr {$cofit_proj <= 135}]
set headroom_ge_132 [expr {$headroom_after >= 132}]

set verdict "FAIL"
set note ""
if {!$ok_pack} {
  set verdict "FAIL"
  set note "proxy under-packed R36=$r36"
} elseif {$headroom_ge_132 && $ok_wns && $ok_tns} {
  set verdict "PASS_NARROW"
  set note "headroom_after>=132 Prefer WNS>=0; proxy only; HS-22 OPEN"
} elseif {$ok_cofit && $ok_dev && $ok_wns && $ok_tns} {
  set verdict "PASS_NARROW"
  set note "co-fit proj BRAM=$cofit_proj<=135 Prefer WNS>=0; WM share collapses 260; HS-22 OPEN; not BOARD_PASS"
  if {!$ok_prefer} {
    set note "$note; prefer<=130 not met (device OK)"
  }
} elseif {$ok_dev && (!$ok_wns || !$ok_tns)} {
  set verdict "LIMIT"
  set note "BRAM fits device but Prefer WNS/TNS miss"
} elseif {!$ok_dev} {
  set verdict "FAIL"
  set note "BRAM $bram_tiles > 135"
} else {
  set verdict "FAIL"
  set note "gates unmet"
}

puts "BRAM_CONSOL_VERDICT=$verdict"
puts "BRAM_CONSOL_NOTE=$note"

set vf [open [file join $rpt_dir VERDICT.txt] w]
puts $vf "VERDICT=$verdict"
puts $vf "NOTE=$note"
puts $vf "BRAM_TILES=$bram_tiles"
puts $vf "WNS=$wns TNS=$tns"
puts $vf "COFIT_PROJ=$cofit_proj ADDITIVE=$bram_additive"
close $vf

write_bitstream -force $bitfile
puts "BRAM_CONSOL_BIT=$bitfile"
# alias kept for log greps
puts "A7NG_BRAM_CONSOLIDATE_DONE"
