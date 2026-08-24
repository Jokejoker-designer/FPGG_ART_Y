# Digilent AXI MIG board stall sweep R2 (mig_board_r2). Never overwrite frozen LM/EAM bits.
# Official mig.prj via XCI — do not hand-edit.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../../..]]
set build_dir  [file join $root_dir build vivado_a7ng_mig_board_r2]
set out_dir    [file join $root_dir build out]
set arch_dir   [file join $root_dir results A7-NATIVE-GRAPH MIG-BOARD-R2]
set ip_xci [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $arch_dir

if {![file exists $ip_xci]} {
    puts stderr "ERROR: MIG IP missing"
    exit 2
}

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng_mig_board_r2.bit]
foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: mig_board_r2 bit path collides with frozen artifact"
        exit 2
    }
}

create_project -force a7ng_mig_board_r2 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

read_ip $ip_xci
generate_target all [get_files $ip_xci]
set mig_rtl [concat \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]

add_files -norecurse [list \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/board uart_tx.sv] \
    [file join $root_dir rtl/ddr clk_arty_ddr.sv] \
    [file join $root_dir rtl/ddr mig_native_wrap.sv] \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_ddr_feed_pp.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_ddr_feed_axi_bridge.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_ddr_feed_mig_top.sv] \
    [file join $root_dir rtl/board arty_a7_ng_mig_board_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7ng03_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_ng_mig_board_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-NG-MIG-BOARD-R2 ==="
synth_design -top arty_a7_ng_mig_board_top -part $part_name -flatten_hierarchy rebuilt
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
foreach to_pat {c166* c200* *ui* *pll* *mmcm*} {
    catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet $to_pat]}
    catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet $to_pat]}
}
write_checkpoint -force [file join $arch_dir mig_board_r2_post_synth.dcp]

puts "=== IMPLEMENT A7-NG-MIG-BOARD-R2 ==="
if {[catch {opt_design -directive ExploreWithRemap} err]} { puts "WARN: opt $err" }
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive AggressiveExplore} perr]} { puts "WARN: phys_opt $perr" }
route_design -directive AggressiveExplore
if {[catch {phys_opt_design -directive AggressiveExplore} perr2]} { puts "WARN: phys_opt2 $perr2" }

report_timing_summary -delay_type min_max -max_paths 10 -file [file join $arch_dir mig_board_r2_timing.rpt]
report_utilization -file [file join $arch_dir mig_board_r2_utilization.rpt]
write_checkpoint -force [file join $arch_dir mig_board_r2_post_route.dcp]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "MIG_BOARD_R2_WNS=$wns"
set fp [open [file join $arch_dir wns.txt] w]
puts $fp $wns
close $fp
if {$wns < 0} {
    puts stderr "ERROR: WNS < 0 ($wns) — HS-12"
    exit 5
}

write_bitstream -force $bitfile
file copy -force $bitfile [file join $arch_dir arty_a7_ng_mig_board_r2.bit]
puts "MIG_BOARD_R2_BIT=$bitfile"
puts "A7NG_MIG_BOARD_R2_IMPL_DONE"
