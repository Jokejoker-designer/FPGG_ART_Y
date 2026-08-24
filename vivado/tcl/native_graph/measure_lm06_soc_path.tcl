# lm06_soc_path — ONE UNKNOWN: LM-06 weight fabric on integrated SoC response path
# H_CANDIDATE: new SoC bit with real weight modules; WNS>=0 TNS=0 BRAM<=135; lm_path sticky≠0 wire
# CONTROL: SoC D65F3524…; frozen LM-06/01R/02M/A0.3 MATCH (never overwrite)
# H_RIVAL: fake lm_path=1; host answers; overwrite frozen LM-06 bit
# Prefer BRAM <= 130; device max 135.

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_lm06_soc]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH LM06-SOC]
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
set bitfile [file join $out_dir arty_a7_ng_lm06_soc.bit]
set target_bram_prefer 130
set device_bram 135

foreach forbidden {arty_a7_lm06.bit arty_a7_eam01r.bit arty_a7_eam02m.bit arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: SoC bit path collides with frozen artifact"
        exit 2
    }
}

# CONTROL bits must remain present
set control_soc [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE arty_a7_ng_integrate_fit_soc.bit]
set frozen_lm06 [file join $out_dir arty_a7_lm06.bit]
foreach c [list $control_soc $frozen_lm06] {
    if {![file exists $c]} {
        puts stderr "ERROR: CONTROL missing $c"
        exit 2
    }
    puts "CONTROL_PRESENT=$c"
}

create_project -force a7ng_lm06_soc $build_dir -part $part_name
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
    [file join $root_dir rtl/memory tile_weight_pingpong.sv] \
    [file join $root_dir rtl/board arty_a7_ng_lm06_soc_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7ng03_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_ng_lm06_soc_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH lm06_soc_path ==="
if {[catch {synth_design -top arty_a7_ng_lm06_soc_top -part $part_name -flatten_hierarchy rebuilt} serr]} {
    puts "LM06_SOC_SYNTH_FAIL=$serr"
    puts "LM06_SOC_VERDICT=FAIL"
    puts "A7NG_LM06_SOC_DONE"
    exit 1
}
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
foreach to_pat {c166* c200* *ui* *pll* *mmcm*} {
    catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet $to_pat]}
    catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet $to_pat]}
}
write_checkpoint -force [file join $out_dir a7ng_lm06_soc_post_synth.dcp]

puts "=== IMPLEMENT lm06_soc_path ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
if {[catch {place_design} perr]} {
    puts "LM06_SOC_PLACE_FAIL=$perr"
    puts "LM06_SOC_VERDICT=FAIL"
    report_utilization -file [file join $rpt_dir lm06_soc_util_place_fail.rpt]
    puts "A7NG_LM06_SOC_DONE"
    exit 1
}
if {[catch {phys_opt_design} poerr]} { puts "WARN: phys_opt $poerr" }
if {[catch {route_design} rerr]} {
    puts "LM06_SOC_ROUTE_FAIL=$rerr"
    puts "LM06_SOC_VERDICT=FAIL"
    report_utilization -file [file join $rpt_dir lm06_soc_util_route_fail.rpt]
    puts "A7NG_LM06_SOC_DONE"
    exit 1
}

report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir lm06_soc_timing.rpt]
report_utilization -file [file join $rpt_dir lm06_soc_util.rpt]
report_utilization -hierarchical -file [file join $rpt_dir lm06_soc_util_hier.rpt]
write_checkpoint -force [file join $out_dir a7ng_lm06_soc_post_route.dcp]

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
set wt_cells [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_lm06_wtile* || NAME =~ *u_lm06_wpp*}]]
set wt_bram [llength [get_cells -quiet -hierarchical -filter {(NAME =~ *u_lm06_wtile* || NAME =~ *u_lm06_wpp*) && (REF_NAME == RAMB36E1 || REF_NAME == RAMB18E1 || ORIG_REF_NAME == RAMB36E1 || ORIG_REF_NAME == RAMB18E1)}]]

puts "LM06_SOC_WNS=$wns"
puts "LM06_SOC_TNS=$tns"
puts "LM06_SOC_WHS=$whs"
puts "LM06_SOC_THS=$ths"
puts "LM06_SOC_BRAM_TILES=$bram_tiles"
puts "LM06_SOC_RAMB36=$ramb36"
puts "LM06_SOC_RAMB18=$ramb18"
puts "LM06_SOC_DSP=$dsp"
puts "LM06_SOC_PE_LANES=$pe_lanes"
puts "LM06_SOC_PE_LUT=$pe_lut"
puts "LM06_SOC_WT_CELLS=$wt_cells"
puts "LM06_SOC_WT_BRAM=$wt_bram"

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
    lappend narrow_notes "LM06_weight_BRAM_ABSENT_H_RIVAL_fake_path"
} else {
    lappend narrow_notes "LM06_weight_fabric_PRESENT_bram=${wt_bram}"
}
if {$pe_lanes < 16 || $pe_lut < 64} {
    if {$verdict eq "PASS"} { set verdict "PASS_NARROW" }
    lappend narrow_notes "PE_not_fully_evidenced_lanes=${pe_lanes}_lut=${pe_lut}"
}
# Full frozen LM-06 act+core NOT on this cut
lappend narrow_notes "LM06_act_u_a_ABSENT_weight_cut_only"
lappend narrow_notes "UART_exam_stub_present_blind_exam_NOT_CLAIMED"
lappend narrow_notes "no_BOARD_PASS"

if {$verdict eq "PASS" || $verdict eq "PASS_NARROW"} {
    write_bitstream -force $bitfile
    file copy -force $bitfile [file join $rpt_dir arty_a7_ng_lm06_soc.bit]
    puts "LM06_SOC_BIT=$bitfile"
} else {
    puts "LM06_SOC_BIT=SKIPPED_${verdict}"
}

set util_file [file join $rpt_dir lm06_soc_util.rpt]
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

puts "LM06_SOC_LUT=$lut_used"
puts "LM06_SOC_FF=$ff_used"
puts "LM06_SOC_BRAM_AUTH=$bram_tiles"
puts "LM06_SOC_DSP_AUTH=$dsp"
puts "LM06_SOC_VERDICT=$verdict"
puts "LM06_SOC_NOTES=[join $narrow_notes {;}]"
puts "A7NG_LM06_SOC_DONE"
