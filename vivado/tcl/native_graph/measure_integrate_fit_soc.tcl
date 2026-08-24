# integrate_fit FULL SoC measure — MIG + PE keep + LM arb + UART stub
# ONE UNKNOWN: can real integrated design meet BRAM<=device, WNS>=0, TNS=0
#   with PE measured post-route and UART exam path stub?
# CONTROL: proxy own_cut SHA D2FC41A7... retained (do not overwrite).
# Never overwrite frozen LM-06 / 01R / 02M / A0.3 bits.
# Prefer BRAM <= 130; device max 135. DSP gate = 0 for NG fabric (MIG/LM stub OK if 0).

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_fit_soc]
set out_dir    [file join $root_dir build out]
set rpt_dir    [file join $root_dir results A7-NATIVE-GRAPH INTEGRATE]
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
set bitfile [file join $out_dir arty_a7_ng_integrate_fit_soc.bit]
set target_bram_prefer 130
set device_bram 135

foreach forbidden {arty_a7_lm06.bit arty_a7_eam01r.bit arty_a7_eam02m.bit arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: SoC bit path collides with frozen artifact"
        exit 2
    }
}

# Preserve proxy control bit if present in results
set proxy_bit [file join $rpt_dir arty_a7_ng_integrate_fit_own_cut.bit]
if {[file exists $proxy_bit]} {
    puts "CONTROL_PROXY_PRESENT=$proxy_bit"
}

create_project -force a7ng_fit_soc $build_dir -part $part_name
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
    [file join $root_dir rtl/board arty_a7_ng_integrate_soc_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7ng03_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_ng_integrate_soc_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH integrate_fit FULL SoC ==="
synth_design -top arty_a7_ng_integrate_soc_top -part $part_name -flatten_hierarchy rebuilt
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
foreach to_pat {c166* c200* *ui* *pll* *mmcm*} {
    catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet $to_pat]}
    catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet $to_pat]}
}
write_checkpoint -force [file join $out_dir a7ng_fit_soc_post_synth.dcp]

puts "=== IMPLEMENT integrate_fit FULL SoC ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN: phys_opt $perr" }
route_design

report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir fit_soc_timing.rpt]
report_utilization -file [file join $rpt_dir fit_soc_util.rpt]
report_utilization -hierarchical -file [file join $rpt_dir fit_soc_util_hier.rpt]
write_checkpoint -force [file join $out_dir a7ng_fit_soc_post_route.dcp]

# Timing numbers
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
set whs [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
set tns 0.0
set ths 0.0
catch {
    set tns [get_property TNS [get_timing_paths -setup -max_paths 1]]
}
# Prefer report_timing_summary properties when available
catch {
    set ts [report_timing_summary -return_string -quiet]
}
# Extract from design
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

# Utilization
set lut [llength [get_cells -quiet -hier -filter {PRIMITIVE_TYPE =~ CLB.LUT.*}]]
set ff  [llength [get_cells -quiet -hier -filter {PRIMITIVE_TYPE =~ REGISTER.SDR.* || PRIMITIVE_TYPE =~ FLOP_LATCH*}]]
# Prefer report util dict
set bram_tiles 0
set dsp 0
set ramb36 0
set ramb18 0
catch {set bram_tiles [lindex [get_property BEL [get_cells -quiet -hier -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*}]] 0]}
# Count Block RAM tiles via cells
set ramb36 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB36E1 || ORIG_REF_NAME == RAMB36E1}]]
set ramb18 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1 || ORIG_REF_NAME == RAMB18E1}]]
set bram_tiles [expr {$ramb36 + ($ramb18 + 1) / 2}]
set dsp [llength [get_cells -quiet -hier -filter {PRIMITIVE_TYPE =~ DSP.*}]]

# PE lane count measured post-route
set pe_lanes [llength [get_cells -quiet -hierarchical -filter {REF_NAME == a7ng_scorer_lane || ORIG_REF_NAME == a7ng_scorer_lane}]]
if {$pe_lanes == 0} {
    set pe_lanes [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_sc/g_lane*}]]
}
set pe_lut [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_sc* && PRIMITIVE_TYPE =~ CLB.LUT.*}]]
set pe_ff  [llength [get_cells -quiet -hierarchical -filter {NAME =~ *u_sc* && (PRIMITIVE_TYPE =~ REGISTER.SDR.* || PRIMITIVE_TYPE =~ FLOP_LATCH*)}]]

puts "FIT_SOC_WNS=$wns"
puts "FIT_SOC_TNS=$tns"
puts "FIT_SOC_WHS=$whs"
puts "FIT_SOC_THS=$ths"
puts "FIT_SOC_BRAM_TILES=$bram_tiles"
puts "FIT_SOC_RAMB36=$ramb36"
puts "FIT_SOC_RAMB18=$ramb18"
puts "FIT_SOC_DSP=$dsp"
puts "FIT_SOC_PE_LANES=$pe_lanes"
puts "FIT_SOC_PE_LUT=$pe_lut"
puts "FIT_SOC_PE_FF=$pe_ff"

set gate_bram_ok 1
set gate_wns_ok 1
set gate_tns_ok 1
set gate_pe_ok 1
set verdict "PASS"
set narrow_notes {}

if {$bram_tiles > $device_bram} {
    set gate_bram_ok 0
    set verdict "FAIL"
    lappend narrow_notes "HS-11_BRAM_${bram_tiles}_gt_${device_bram}"
} elseif {$bram_tiles > $target_bram_prefer} {
    lappend narrow_notes "BRAM_${bram_tiles}_gt_prefer_${target_bram_prefer}_LIMIT"
    if {$verdict eq "PASS"} { set verdict "PASS_NARROW" }
}
if {$wns < 0} {
    set gate_wns_ok 0
    set verdict "FAIL"
    lappend narrow_notes "HS-12_WNS_${wns}"
}
if {$tns != 0 && $tns != 0.0} {
    # floating compare: fail if negative TNS
    if {$tns < 0} {
        set gate_tns_ok 0
        set verdict "FAIL"
        lappend narrow_notes "HS-12_TNS_${tns}"
    }
}
if {$pe_lanes < 16 || $pe_lut < 64} {
    set gate_pe_ok 0
    if {$verdict eq "PASS"} { set verdict "PASS_NARROW" }
    lappend narrow_notes "PE_not_fully_evidenced_lanes=${pe_lanes}_lut=${pe_lut}"
}
# Full LM-06 fabric absent by design — always document LIMIT
lappend narrow_notes "LM06_weight_fabric_ABSENT_arbitration_compose_only"
lappend narrow_notes "UART_exam_stub_present_blind_exam_DEFERRED"

if {$verdict eq "PASS" || $verdict eq "PASS_NARROW"} {
    write_bitstream -force $bitfile
    puts "FIT_SOC_BIT=$bitfile"
} else {
    puts "FIT_SOC_BIT=SKIPPED_FAIL"
}

# Parse util report for authoritative LUT/FF/BRAM if present
set util_file [file join $rpt_dir fit_soc_util.rpt]
set lut_used -1
set ff_used -1
set bram_used -1
set dsp_used -1
if {[file exists $util_file]} {
    set uf [open $util_file r]
    set utxt [read $uf]
    close $uf
    regexp {Slice LUTs[^\n]*?\|\s*(\d+)} $utxt -> lut_used
    regexp {Register as Flip Flop[^\n]*?\|\s*(\d+)|Slice Registers[^\n]*?\|\s*(\d+)} $utxt -> ff_a ff_b
    if {$ff_a ne ""} { set ff_used $ff_a } elseif {[info exists ff_b] && $ff_b ne ""} { set ff_used $ff_b }
    regexp {Block RAM Tile[^\n]*?\|\s*(\d+)} $utxt -> bram_used
    regexp {\|\s*DSPs\s*\|\s*(\d+)} $utxt -> dsp_used
}
if {$bram_used >= 0} { set bram_tiles $bram_used }
if {$dsp_used >= 0} { set dsp $dsp_used }
if {$lut_used >= 0} { set lut $lut_used }
if {$ff_used >= 0} { set ff $ff_used }

puts "FIT_SOC_LUT=$lut"
puts "FIT_SOC_FF=$ff"
puts "FIT_SOC_BRAM_AUTH=$bram_tiles"
puts "FIT_SOC_DSP_AUTH=$dsp"
puts "FIT_SOC_VERDICT=$verdict"
puts "FIT_SOC_NOTES=[join $narrow_notes {;}]"
puts "A7NG_INTEGRATE_FIT_SOC_DONE"
