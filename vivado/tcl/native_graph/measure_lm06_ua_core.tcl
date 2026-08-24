# lm06_ua_core — ONE UNKNOWN: act u_a with weight tiles on SoC
# H_CANDIDATE: named u_a (act_ram128k16) in hier; WNS>=0 TNS=0 BRAM<=135; new bit
# CONTROL: weight-cut SoC D61BA6D4…; frozen LM-06/01R/02M/A0.3 MATCH (never overwrite)
# H_RIVAL: fake lm_path; overwrite frozen LM-06; host answers / BOARD_PASS
# Prefer BRAM <= 130; device max 135. Honest LIMIT if fit fails.

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_lm06_ua]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH LM06-UA]
set ip_xci [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $rpt_dir

if {![file exists $ip_xci]} {
    puts stderr "ERROR: MIG IP missing"
    exit 2
}

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_lm06_ua_soc.bit]
set target_bram_prefer 130
set device_bram 135

foreach forbidden {arty_a7_lm06.bit arty_a7_eam01r.bit arty_a7_eam02m.bit arty_a7_eam03e arty_a7_ng_lm06_soc.bit} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: SoC bit path collides with frozen/CONTROL artifact"
        exit 2
    }
}

# CONTROL bits must remain present (weight-cut + frozen LM-06)
set control_soc [file join $root_dir results A7-NATIVE-GRAPH LM06-SOC arty_a7_ng_lm06_soc.bit]
set frozen_lm06 [file join $out_dir arty_a7_lm06.bit]
foreach c [list $control_soc $frozen_lm06] {
    if {![file exists $c]} {
        puts stderr "ERROR: CONTROL missing $c"
        exit 2
    }
    puts "CONTROL_PRESENT=$c"
}

create_project -force a7ng_lm06_ua $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

read_ip $ip_xci
generate_target all [get_files $ip_xci]
set mig_rtl [concat \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]

add_files -norecurse [list \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/board uart_rx.sv] \
    [file join $root_dir rtl/board uart_tx.sv] \
    [file join $root_dir rtl/ddr clk_arty_ddr.sv] \
    [file join $root_dir rtl/ddr mig_native_wrap.sv] \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_bram_hotset.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_shard_fetch.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_lane.sv] \
    [file join $root_dir rtl/native_graph/scorer a7ng_scorer_array.sv] \
    [file join $root_dir rtl/native_graph/lm a7ng_evidence_compose.sv] \
    [file join $root_dir rtl/native_graph/integrate a7ng_lm_graph_arb.sv] \
    [file join $root_dir rtl/native_graph/integrate a7ng_exam_uart_stub.sv] \
    [file join $root_dir rtl/lm a7lm06_pkg.sv] \
    [file join $root_dir rtl/lm weight_bram_tdp8.sv] \
    [file join $root_dir rtl/lm weight_tile803k.sv] \
    [file join $root_dir rtl/lm act_ram128k16.sv] \
    [file join $root_dir rtl/memory tile_weight_pingpong.sv] \
    [file join $root_dir rtl/board arty_a7_ng_lm06_ua_soc_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7ng03_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_ng_lm06_ua_soc_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH lm06_ua_core ==="
if {[catch {synth_design -top arty_a7_ng_lm06_ua_soc_top -part $part_name -flatten_hierarchy rebuilt} serr]} {
    puts "LM06_UA_SYNTH_FAIL=$serr"
    puts "LM06_UA_VERDICT=FAIL"
    puts "A7NG_LM06_UA_DONE"
    exit 1
}
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
foreach to_pat {c166* c200* *ui* *pll* *mmcm*} {
    catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet $to_pat]}
    catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet $to_pat]}
}
write_checkpoint -force [file join $out_dir a7ng_lm06_ua_post_synth.dcp]

puts "=== IMPLEMENT lm06_ua_core ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
if {[catch {place_design} perr]} {
    puts "LM06_UA_PLACE_FAIL=$perr"
    puts "LM06_UA_VERDICT=FAIL"
    report_utilization -file [file join $rpt_dir lm06_ua_util_place_fail.rpt]
    puts "A7NG_LM06_UA_DONE"
    exit 1
}
if {[catch {phys_opt_design} poerr]} { puts "WARN: phys_opt $poerr" }
if {[catch {route_design} rerr]} {
    puts "LM06_UA_ROUTE_FAIL=$rerr"
    puts "LM06_UA_VERDICT=FAIL"
    report_utilization -file [file join $rpt_dir lm06_ua_util_route_fail.rpt]
    puts "A7NG_LM06_UA_DONE"
    exit 1
}

report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir lm06_ua_timing.rpt]
report_utilization -file [file join $rpt_dir lm06_ua_util.rpt]
report_utilization -hierarchical -file [file join $rpt_dir lm06_ua_util_hier.rpt]
write_checkpoint -force [file join $out_dir a7ng_lm06_ua_post_route.dcp]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
set setup_paths [get_timing_paths -setup -max_paths 1000 -nworst 1]
set tns_acc 0.0
foreach p $setup_paths {
    set s [get_property SLACK $p]
    if {$s < 0} { set tns_acc [expr {$tns_acc + $s}] }
}
set tns $tns_acc
set hold_paths [get_timing_paths -hold -max_paths 1000 -nworst 1]
set ths_acc 0.0
foreach p $hold_paths {
    set s [get_property SLACK $p]
    if {$s < 0} { set ths_acc [expr {$ths_acc + $s}] }
}
set ths $ths_acc

set ramb36 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB36E1 || ORIG_REF_NAME == RAMB36E1}]]
set ramb18 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1 || ORIG_REF_NAME == RAMB18E1}]]
set bram_tiles [expr {$ramb36 + ($ramb18 + 1) / 2}]
set dsp [llength [get_cells -quiet -hier -filter {PRIMITIVE_TYPE =~ DSP.*}]]
set pe_lanes [llength [get_cells -quiet -hierarchical -filter {REF_NAME == a7ng_scorer_lane || ORIG_REF_NAME == a7ng_scorer_lane}]]
if {$pe_lanes == 0} {
    set pe_lanes [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_sc/g_lane*}]]
}
set pe_lut [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_sc* && PRIMITIVE_TYPE =~ CLB.LUT.*}]]
set wt_bram [llength [get_cells -quiet -hierarchical -filter {(NAME =~ *u_lm06_wtile* || NAME =~ *u_lm06_wpp*) && (REF_NAME == RAMB36E1 || REF_NAME == RAMB18E1 || ORIG_REF_NAME == RAMB36E1 || ORIG_REF_NAME == RAMB18E1)}]]
set ua_cells [llength [get_cells -quiet -hierarchical -filter {NAME =~ */u_a || NAME =~ */u_a/* || REF_NAME == act_ram128k16 || ORIG_REF_NAME == act_ram128k16}]]
set ua_bram [llength [get_cells -quiet -hierarchical -filter {(NAME =~ *u_a*) && (REF_NAME == RAMB36E1 || REF_NAME == RAMB18E1 || ORIG_REF_NAME == RAMB36E1 || ORIG_REF_NAME == RAMB18E1)}]]

puts "LM06_UA_WNS=$wns"
puts "LM06_UA_TNS=$tns"
puts "LM06_UA_WHS=$whs"
puts "LM06_UA_THS=$ths"
puts "LM06_UA_BRAM_TILES=$bram_tiles"
puts "LM06_UA_RAMB36=$ramb36"
puts "LM06_UA_RAMB18=$ramb18"
puts "LM06_UA_DSP=$dsp"
puts "LM06_UA_PE_LANES=$pe_lanes"
puts "LM06_UA_PE_LUT=$pe_lut"
puts "LM06_UA_WT_BRAM=$wt_bram"
puts "LM06_UA_UA_CELLS=$ua_cells"
puts "LM06_UA_UA_BRAM=$ua_bram"

set verdict "PASS"
set narrow_notes {}

if {$bram_tiles > $device_bram} {
    set verdict "FAIL"
    lappend narrow_notes "HS-11_BRAM_${bram_tiles}_gt_${device_bram}"
} elseif {$bram_tiles > $target_bram_prefer} {
    if {$verdict eq "PASS"} { set verdict "PASS_NARROW" }
    lappend narrow_notes "BRAM_${bram_tiles}_gt_prefer_${target_bram_prefer}_LIMIT"
}
if {$wns < 0} {
    set verdict "FAIL"
    lappend narrow_notes "HS-12_WNS_${wns}"
}
if {$tns < 0} {
    set verdict "FAIL"
    lappend narrow_notes "HS-12_TNS_${tns}"
}
if {$wt_bram < 1} {
    set verdict "FAIL"
    lappend narrow_notes "LM06_weight_BRAM_ABSENT_H_RIVAL"
} else {
    lappend narrow_notes "LM06_weight_fabric_PRESENT_bram=${wt_bram}"
}
if {$ua_bram < 1} {
    set verdict "FAIL"
    lappend narrow_notes "LM06_act_u_a_BRAM_ABSENT"
} else {
    lappend narrow_notes "LM06_act_u_a_PRESENT_bram=${ua_bram}"
}
if {$pe_lanes < 16 || $pe_lut < 64} {
    if {$verdict eq "PASS"} { set verdict "PASS_NARROW" }
    lappend narrow_notes "PE_not_fully_evidenced_lanes=${pe_lanes}_lut=${pe_lut}"
}
# Full TinyGPT + DSP still ABSENT on this cut
lappend narrow_notes "TinyGPT_core_DSP_ABSENT_LIMIT"
lappend narrow_notes "UART_exam_stub_present_blind_exam_NOT_CLAIMED"
lappend narrow_notes "no_BOARD_PASS"

if {$verdict eq "PASS" || $verdict eq "PASS_NARROW"} {
    write_bitstream -force $bitfile
    file copy -force $bitfile [file join $rpt_dir arty_a7_ng_lm06_ua_soc.bit]
    puts "LM06_UA_BIT=$bitfile"
} else {
    # Still archive reports; no bit sold as PASS
    puts "LM06_UA_BIT=SKIPPED_${verdict}"
    # If BRAM over device, label LIMIT class for honest fit break
    if {$bram_tiles > $device_bram} {
        puts "LM06_UA_FIT_CLASS=LIMIT_HS11"
    }
}

set util_file [file join $rpt_dir lm06_ua_util.rpt]
set lut_used -1
set ff_used -1
set bram_used -1
set dsp_used -1
if {[file exists $util_file]} {
    set uf [open $util_file r]
    set utxt [read $uf]
    close $uf
    regexp {Slice LUTs[^\n]*?\|\s*(\d+)} $utxt -> lut_used
    regexp {Register as Flip Flop[^\n]*?\|\s*(\d+)} $utxt -> ff_used
    regexp {Block RAM Tile[^\n]*?\|\s*(\d+)} $utxt -> bram_used
    regexp {\|\s*DSPs\s*\|\s*(\d+)} $utxt -> dsp_used
}
if {$bram_used >= 0} { set bram_tiles $bram_used }
if {$dsp_used >= 0} { set dsp $dsp_used }

puts "LM06_UA_LUT=$lut_used"
puts "LM06_UA_FF=$ff_used"
puts "LM06_UA_BRAM_AUTH=$bram_tiles"
puts "LM06_UA_DSP_AUTH=$dsp"
puts "LM06_UA_VERDICT=$verdict"
puts "LM06_UA_NOTES=[join $narrow_notes {;}]"
puts "A7NG_LM06_UA_DONE"
