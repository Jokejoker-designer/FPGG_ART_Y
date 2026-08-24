# A7-EAM-01R: OOC synth + impl of eam01r_core. No bitstream. No LM / 00B overwrite.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7eam01r]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-01R]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $res_dir

set part_name xc7a100tcsg324-1
create_project -force a7eam01r $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/eam a7eam00_pkg.sv] \
    [file join $root_dir rtl/eam a7eam01r_pkg.sv] \
    [file join $root_dir rtl/eam eam_tdp256.sv] \
    [file join $root_dir rtl/eam eam01r_ibank.sv] \
    [file join $root_dir rtl/eam eam01r_core.sv]]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7eam01r.xdc]
set_property top eam01r_core [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-EAM-01R OOC ==="
if {[catch {synth_design -top eam01r_core -part $part_name -mode out_of_context -flatten_hierarchy rebuilt} serr]} {
    puts stderr "ERROR: synth_design failed: $serr"
    exit 2
}
write_checkpoint -force [file join $out_dir a7eam01r_post_synth.dcp]
report_utilization -file [file join $out_dir a7eam01r_utilization_synth.rpt]
report_ram_utilization -file [file join $out_dir a7eam01r_ram_synth.rpt]

set n_ramb36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n_ramb18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set n_bram_eq [expr {$n_ramb36 + ($n_ramb18 + 1) / 2}]
set n_lutram [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAM64* || REF_NAME =~ RAM32* || REF_NAME =~ RAM128* || REF_NAME =~ SRL*}]]
set n_fd     [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ FD*}]]
set n_lut    [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ LUT*}]]
set n_dsp    [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

puts "INFER ramb36=$n_ramb36 ramb18=$n_ramb18 bram_eq=$n_bram_eq lutram=$n_lutram fd=$n_fd lut=$n_lut dsp=$n_dsp"

set synth_pass 1
set bram_ok    [expr {$n_bram_eq >= 20 && $n_bram_eq < 60}]
set no_explode [expr {($n_lutram <= 64) && ($n_fd < 12000)}]
set lut_ok     [expr {$n_lut < 10000}]
set dsp_ok     [expr {$n_dsp == 0}]

set io_clk [get_clocks -quiet eam_clk]
if {[llength $io_clk]} {
    foreach p [get_ports -quiet -filter {DIRECTION == IN}] {
        if {$p eq "clk" || $p eq "rst_n"} { continue }
        set_input_delay -clock $io_clk -max 2.000 $p
        set_input_delay -clock $io_clk -min 0.500 $p
    }
    foreach p [get_ports -quiet -filter {DIRECTION == OUT}] {
        set_output_delay -clock $io_clk -max 2.000 $p
        set_output_delay -clock $io_clk -min 0.500 $p
    }
}

puts "=== IMPLEMENT A7-EAM-01R OOC ==="
if {[catch {opt_design} err]} {
    puts "WARN: opt_design: $err"
}
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive Explore} perr]} {
    puts "WARN: phys_opt: $perr"
}
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7eam01r_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7eam01r_timing_route.rpt]
report_utilization -file [file join $out_dir a7eam01r_utilization_route.rpt]
report_ram_utilization -file [file join $out_dir a7eam01r_ram_route.rpt]

set wns 0.0
set tns 0.0
set trpt [file join $out_dir a7eam01r_timing_route.rpt]
set fh [open $trpt r]
set txt [read $fh]
close $fh
if {[regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s+([-0-9.]+)\s+([-0-9.]+)} $txt -> wns_s tns_s]} {
    set wns $wns_s
    set tns $tns_s
}
puts "POST_ROUTE_WNS=$wns TNS=$tns"

set clk_ok 0
set clks [get_clocks -quiet eam_clk]
if {[llength $clks]} {
    set per [get_property PERIOD $clks]
    puts "CLOCK eam_clk PERIOD=$per"
    if {abs($per - 10.0) < 0.001} { set clk_ok 1 }
}
set timing_ok [expr {($wns >= 0.0) && (abs($tns) < 0.0005)}]

set man [file join $res_dir gates_01r.json]
set jf [open $man w]
set all_ok [expr {$synth_pass && $bram_ok && $no_explode && $lut_ok && $dsp_ok && $timing_ok && $clk_ok}]
puts $jf [format \
{{"candidate":"01r","part":"%s","synth_pass":%s,"bram_eq":%d,"ramb36":%d,"ramb18":%d,"lutram":%d,"lut":%d,"ff":%d,"dsp":%d,"bram_ok":%s,"lut_ok":%s,"dsp_ok":%s,"wns_ns":%s,"tns_ns":%s,"timing_ok":%s,"clk_100mhz":%s,"pass":%s}} \
    $part_name \
    [expr {$synth_pass ? "true" : "false"}] \
    $n_bram_eq $n_ramb36 $n_ramb18 $n_lutram $n_lut $n_fd $n_dsp \
    [expr {$bram_ok ? "true" : "false"}] \
    [expr {$lut_ok ? "true" : "false"}] \
    [expr {$dsp_ok ? "true" : "false"}] \
    $wns $tns \
    [expr {$timing_ok ? "true" : "false"}] \
    [expr {$clk_ok ? "true" : "false"}] \
    [expr {$all_ok ? "true" : "false"}]]
close $jf
puts "WROTE $man"

if {!$all_ok} {
    puts stderr "A7_EAM01R_GATES_FAIL bram_eq=$n_bram_eq lut=$n_lut dsp=$n_dsp WNS=$wns TNS=$tns"
    exit 5
}
puts "A7_EAM01R_GATES_PASS WNS=$wns TNS=$tns bram_eq=$n_bram_eq lut=$n_lut ff=$n_fd"
