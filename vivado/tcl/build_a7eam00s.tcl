# A7-EAM-00S: OOC synth + impl + post-synth funcsim. No bitstream. No LM bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7eam00s]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-00]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $res_dir

set part_name xc7a100tcsg324-1
create_project -force a7eam00s $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/eam a7eam00_pkg.sv] \
    [file join $root_dir rtl/eam eam_tdp256.sv] \
    [file join $root_dir rtl/eam eam_controller.sv] \
    [file join $root_dir rtl/eam eam_core.sv] \
    [file join $root_dir rtl/eam eam_axil.sv] \
    [file join $root_dir rtl/eam a7eam00_top.sv]]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints a7eam00.xdc]
set_property top a7eam00_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-EAM-00S OOC ==="
if {[catch {synth_design -top a7eam00_top -part $part_name -mode out_of_context -flatten_hierarchy rebuilt} serr]} {
    puts stderr "ERROR: synth_design failed: $serr"
    exit 2
}
write_checkpoint -force [file join $out_dir a7eam00s_post_synth.dcp]
report_utilization -file [file join $out_dir a7eam00s_utilization_synth.rpt]
write_verilog -mode funcsim -force [file join $out_dir a7eam00s_funcsim.v]

set n_ramb36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n_ramb18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set n_bram_eq [expr {$n_ramb36 + ($n_ramb18 + 1) / 2}]
set n_lutram [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAM64* || REF_NAME =~ RAM32* || REF_NAME =~ RAM128* || REF_NAME =~ SRL*}]]
set n_fd     [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ FD*}]]
set n_lut    [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ LUT*}]]

puts "INFER ramb36=$n_ramb36 ramb18=$n_ramb18 bram_eq=$n_bram_eq lutram=$n_lutram fd=$n_fd lut=$n_lut"

set synth_pass 1
set bram_ok    [expr {$n_bram_eq >= 28}]
set no_explode [expr {($n_lutram <= 32) && ($n_fd < 12000)}]
set margin_ok  [expr {($n_lut < 8000) && ($n_fd < 8000) && ($n_bram_eq < 50)}]

# Interface delays after synth (registered I/O). 2 ns external, 8 ns on-chip.
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

puts "=== IMPLEMENT A7-EAM-00S OOC ==="
if {[catch {opt_design} err]} {
    puts "WARN: opt_design: $err"
}
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive Explore} perr]} {
    puts "WARN: phys_opt: $perr"
}
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7eam00s_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7eam00s_timing_route.rpt]
report_utilization -file [file join $out_dir a7eam00s_utilization_route.rpt]
report_clocks -file [file join $out_dir a7eam00s_clocks.rpt]

set wns 0.0
set tns 0.0
set tp [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $tp]} {
    set wns [get_property SLACK $tp]
}
set trpt [file join $out_dir a7eam00s_timing_route.rpt]
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

set bad_cw {}
foreach line [split $txt \n] {}
set slog [file join $root_dir build a7eam00s.log]
if {[file exists $slog]} {
    set lf [open $slog r]
    set ltxt [read $lf]
    close $lf
} else {
    set ltxt ""
}
foreach line [split $ltxt \n] {
    if {[string match {*CRITICAL WARNING*} $line]
        && [regexp -nocase {collision|multipl(e|y).{0,16}driver|clocking|multi-driven} $line]} {
        lappend bad_cw $line
    }
}
set cw_ok [expr {[llength $bad_cw] == 0}]
puts "CW_RELEVANT count=[llength $bad_cw]"

puts "=== POST-SYNTH FUNCSIM ==="
set xsimdir [file join $root_dir tests xsim]
set net [file join $out_dir a7eam00s_funcsim.v]
set tb  [file join $xsimdir tb_a7eam00.sv]
set pkg [file join $root_dir rtl/eam a7eam00_pkg.sv]
set glbl [file join C:/2026.1/Vivado/data/verilog/src/glbl.v]
if {[info exists ::env(XILINX_VIVADO)] && $::env(XILINX_VIVADO) ne ""} {
    set g2 [file join $::env(XILINX_VIVADO) data verilog src glbl.v]
    if {[file exists $g2]} { set glbl $g2 }
}
cd $xsimdir
set func_ok 0
if {[catch {exec xvlog -sv $pkg $net $tb $glbl} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
} else {
    puts $vlog_out
    if {[catch {exec xelab tb_a7eam00 glbl -s tb_a7eam00s -timescale 1ns/1ps -L unisims_ver -L unimacro_ver} elab_out]} {
        puts $elab_out
        puts "XELAB_FAIL"
    } else {
        puts $elab_out
        if {[catch {exec xsim tb_a7eam00s -runall} sim_out]} {
            puts $sim_out
            puts "XSIM_FAIL"
        } else {
            puts $sim_out
            if {[string match "*A7EAM00_XSIM_PASS*" $sim_out]} {
                set func_ok 1
            }
        }
    }
}

set all_ok [expr {$synth_pass && $bram_ok && $no_explode && $margin_ok && $timing_ok && $clk_ok && $cw_ok && $func_ok}]

set man [file join $res_dir gates_00s.json]
set jf [open $man w]
puts $jf [format \
{{"candidate":"00s","part":"%s","synth_pass":%s,"bram_eq":%d,"ramb36":%d,"ramb18":%d,"lutram":%d,"lut":%d,"ff":%d,"bram_ok":%s,"no_explode":%s,"margin_ok":%s,"wns_ns":%s,"tns_ns":%s,"timing_ok":%s,"clk_100mhz":%s,"cw_ok":%s,"funcsim_ok":%s,"pass":%s}} \
    $part_name \
    [expr {$synth_pass ? "true" : "false"}] \
    $n_bram_eq $n_ramb36 $n_ramb18 $n_lutram $n_lut $n_fd \
    [expr {$bram_ok ? "true" : "false"}] \
    [expr {$no_explode ? "true" : "false"}] \
    [expr {$margin_ok ? "true" : "false"}] \
    $wns $tns \
    [expr {$timing_ok ? "true" : "false"}] \
    [expr {$clk_ok ? "true" : "false"}] \
    [expr {$cw_ok ? "true" : "false"}] \
    [expr {$func_ok ? "true" : "false"}] \
    [expr {$all_ok ? "true" : "false"}]]
close $jf
puts "WROTE $man"

if {!$all_ok} {
    puts stderr "A7_EAM00S_FAIL synth=$synth_pass bram=$bram_ok explode=$no_explode margin=$margin_ok timing=$timing_ok clk=$clk_ok cw=$cw_ok func=$func_ok WNS=$wns TNS=$tns bram_eq=$n_bram_eq lutram=$n_lutram lut=$n_lut ff=$n_fd"
    exit 5
}
puts "A7_EAM00S_PASS WNS=$wns TNS=$tns bram_eq=$n_bram_eq lut=$n_lut ff=$n_fd"
