# A7-LM-04: 100k DDR-persist Transformer. Writes arty_a7_lm04.bit only.
# Requires frozen 00/01/02/03 bits with contract SHA. Does not start LM-05.
# Do not program until post-route WNS>=0 and preferably post-route sim matches.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm04]
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
create_project -force a7lm04 $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define SYNTHESIS [current_fileset]

read_ip $ip_xci
generate_target all [get_files $ip_xci]
set mig_rtl [concat \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
    [glob -nocomplain [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]
add_files -norecurse [list \
    [file join $root_dir rtl board sync_bits.sv] \
    [file join $root_dir rtl board clkdiv2.sv] \
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
    [file join $root_dir rtl lm a7lm04_pkg.sv] \
    [file join $root_dir rtl lm isqrt32.sv] \
    [file join $root_dir rtl lm floordiv_s48.sv] \
    [file join $root_dir rtl lm weight_bram100k.sv] \
    [file join $root_dir rtl lm act_ram64k.sv] \
    [file join $root_dir rtl lm tiny_gpt100k_core.sv] \
    [file join $root_dir rtl lm lm04_persist.sv] \
    [file join $root_dir rtl board arty_a7_lm04_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints arty_a7_lm04.xdc] \
    [file join $root_dir constraints a7lm01_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_lm04_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTHESIS A7-LM-04 ==="
synth_design -top arty_a7_lm04_top -part $part_name -flatten_hierarchy rebuilt -directive PerformanceOptimized
puts "CLOCKS=[get_clocks]"
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *pll*]
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *pll*]
write_checkpoint -force [file join $out_dir a7lm04_post_synth.dcp]
report_utilization -file [file join $out_dir a7lm04_utilization_synth.rpt]

puts "=== IMPLEMENT A7-LM-04 ==="
opt_design -directive ExploreWithRemap
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore
phys_opt_design -directive AggressiveExplore
write_checkpoint -force [file join $out_dir a7lm04_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm04_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm04_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.0} {
    puts stderr "ERROR: WNS=$wns"
    exit 4
}

proc sha256_file {path} {
    set out [exec powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '$path').Hash"]
    return [string toupper [string trim $out]]
}

set frozen_sha [dict create \
    arty_a7_lm00.bit 449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783 \
    arty_a7_lm01.bit 96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8 \
    arty_a7_lm02.bit 7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4 \
    arty_a7_lm03.bit C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1]
foreach frozen {arty_a7_lm00.bit arty_a7_lm01.bit arty_a7_lm02.bit arty_a7_lm03.bit} {
    set fp [file join $out_dir $frozen]
    if {![file exists $fp]} {
        puts stderr "ERROR: refuse to write LM-04 without frozen $frozen"
        exit 5
    }
    set got [sha256_file $fp]
    set exp [dict get $frozen_sha $frozen]
    if {$got ne $exp} {
        puts stderr "ERROR: frozen SHA mismatch $frozen got=$got exp=$exp"
        exit 6
    }
    puts "FROZEN_OK $frozen $got"
}
write_bitstream -force [file join $out_dir arty_a7_lm04.bit]
puts "A7_LM04_BUILD_PASS bitstream=[file join $out_dir arty_a7_lm04.bit] WNS=$wns"
