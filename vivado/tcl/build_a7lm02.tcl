set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm02]
set out_dir [file join $root_dir build out]
set ip_xci [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
file mkdir $build_dir
file mkdir $out_dir

if {![file exists $ip_xci]} {
    puts stderr "ERROR: generate MIG IP first"
    exit 2
}

set part_name xc7a100tcsg324-1
create_project -force a7lm02 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

read_ip $ip_xci
generate_target all [get_files $ip_xci]
set mig_rtl [concat \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]
add_files -norecurse [list \
    [file join $root_dir rtl board sync_bits.sv] \
    [file join $root_dir rtl board uart_tx.sv] \
    [file join $root_dir rtl board uart_rx.sv] \
    [file join $root_dir rtl lm lm02_tx.sv] \
    [file join $root_dir rtl ddr clk_arty_ddr.sv] \
    [file join $root_dir rtl ddr mig_native_wrap.sv] \
    [file join $root_dir rtl ddr ddr_tile_dma.sv] \
    [file join $root_dir rtl tensor a7lm02_pkg.sv] \
    [file join $root_dir rtl tensor xorshift32.sv] \
    [file join $root_dir rtl tensor mac_lane.sv] \
    [file join $root_dir rtl tensor mac_array_128.sv] \
    [file join $root_dir rtl tensor requantize.sv] \
    [file join $root_dir rtl tensor gemv_scheduler.sv] \
    [file join $root_dir rtl tensor gemm_scheduler.sv] \
    [file join $root_dir rtl tensor prbs_tile_fill.sv] \
    [file join $root_dir rtl memory tile_weight_pingpong.sv] \
    [file join $root_dir rtl memory tile_activation.sv] \
    [file join $root_dir rtl memory psum_bank.sv] \
    [file join $root_dir rtl control tensor_microseq.sv] \
    [file join $root_dir rtl board arty_a7_lm02_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7lm01_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_lm02_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTHESIS A7-LM-02 ==="
synth_design -top arty_a7_lm02_top -part $part_name -flatten_hierarchy rebuilt
puts "CLOCKS=[get_clocks]"
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *pll*]
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *ui*]
catch {set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -of_objects [get_pins -quiet u_clk/u166/O]]}
catch {set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -of_objects [get_pins -quiet u_clk/u166/O]]}
write_checkpoint -force [file join $out_dir a7lm02_post_synth.dcp]
report_utilization -file [file join $out_dir a7lm02_utilization_synth.rpt]

puts "=== IMPLEMENT A7-LM-02 ==="
opt_design
place_design
phys_opt_design
route_design
phys_opt_design
write_checkpoint -force [file join $out_dir a7lm02_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm02_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm02_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.0} {
    puts stderr "ERROR: WNS=$wns"
    exit 4
}
foreach frozen {arty_a7_lm00.bit arty_a7_lm01.bit} {
    if {![file exists [file join $out_dir $frozen]]} {
        puts stderr "ERROR: refuse to write LM-02 without frozen $frozen"
        exit 5
    }
}
write_bitstream -force [file join $out_dir arty_a7_lm02.bit]
puts "A7_LM02_BUILD_PASS bitstream=[file join $out_dir arty_a7_lm02.bit] WNS=$wns"
