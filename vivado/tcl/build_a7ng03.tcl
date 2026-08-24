# NG-03 MIG + shard hotset. Never overwrite frozen LM/EAM bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7ng03]
set out_dir    [file join $root_dir build out]
set ip_xci [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
file mkdir $build_dir
file mkdir $out_dir

if {![file exists $ip_xci]} {
    puts stderr "ERROR: MIG IP missing"
    exit 2
}

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_ng03.bit]
foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e} {
    if {[string match *$forbidden* [file tail $bitfile]]} {
        puts stderr "REFUSE: NG-03 bit path collides with frozen artifact"
        exit 2
    }
}

create_project -force a7ng03 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

read_ip $ip_xci
generate_target all [get_files $ip_xci]
# Same as LM-01: XCI + explicit user_design RTL (wrap needs mig_7series_0)
set mig_rtl [concat \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]

add_files -norecurse [list \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/ddr clk_arty_ddr.sv] \
    [file join $root_dir rtl/ddr mig_native_wrap.sv] \
    [file join $root_dir rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_bram_hotset.sv] \
    [file join $root_dir rtl/native_graph/memory a7ng_shard_fetch.sv] \
    [file join $root_dir rtl/board arty_a7_ng03_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7ng03_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_ng03_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-NG-03 ==="
synth_design -top arty_a7_ng03_top -part $part_name -flatten_hierarchy rebuilt
# Async CDC after clocks exist (avoid remove_from_collection — broken in some batch contexts)
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
foreach to_pat {c166* c200* *ui* *pll* *mmcm*} {
    catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet $to_pat]}
    catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet $to_pat]}
}
write_checkpoint -force [file join $out_dir a7ng03_post_synth.dcp]

puts "=== IMPLEMENT A7-NG-03 ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN: phys_opt $perr" }
route_design

set rpt_dir [file join $root_dir results A7-NATIVE-GRAPH NG-03]
file mkdir $rpt_dir
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $rpt_dir a7ng03_timing_route.rpt]
report_utilization -file [file join $rpt_dir a7ng03_utilization_route.rpt]
write_checkpoint -force [file join $out_dir a7ng03_post_route.dcp]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "NG03_WNS=$wns"
if {$wns < 0} {
    puts stderr "ERROR: WNS < 0 ($wns)"
    exit 5
}

write_bitstream -force $bitfile
puts "NG03_BIT=$bitfile"
puts "A7NG03_IMPL_DONE"
