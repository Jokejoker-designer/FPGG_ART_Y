# A7-LM-04 R5 isolated rebuild for Arty A7-100T / Vivado 2026.1.
# Run:
#   C:/2026.1/Vivado/bin/vivado.bat -mode batch -notrace \
#     -source vivado/tcl/build_a7lm04r5.tcl \
#     -log build/a7lm04r5_build.log -journal build/a7lm04r5_build.jou
# Outputs: build/out/arty_a7_lm04r5.bit, R5 DCP/timing/utilization reports.
# Next: program_a7lm04r5.tcl, then tools/a7lm04_close_ladder_r5.py.

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm04r5]
set out_dir [file join $root_dir build out]
set ip_xci [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root_dir vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
file mkdir $build_dir
file mkdir $out_dir

proc sha256_file {path} {
    set escaped [string map {' ''} $path]
    set out [exec powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '$escaped').Hash"]
    return [string toupper [string trim $out]]
}

if {![file exists $ip_xci]} {
    puts stderr "ERROR: generate the frozen MIG IP first: $ip_xci"
    exit 2
}

# Fail closed before synthesis if any frozen or historical evidence was mutated.
set immutable_sha [dict create \
    arty_a7_lm00.bit 449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783 \
    arty_a7_lm01.bit 96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8 \
    arty_a7_lm02.bit 7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4 \
    arty_a7_lm03.bit C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1 \
    arty_a7_lm04.bit 0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2 \
    arty_a7_lm04r.bit 6BED0DE83922B45BABBD8D2DD0F46F0F469474CB9F0A8A1DF96D1421817EF6B9 \
    arty_a7_lm04r3.bit FAC912B3DB543C312565FAA58A457A568E091F156592E4DC82987E92FB8E0318]
foreach name [dict keys $immutable_sha] {
    set path [file join $out_dir $name]
    if {![file exists $path]} {
        puts stderr "ERROR: required immutable artifact missing: $path"
        exit 3
    }
    set got [sha256_file $path]
    set expected [dict get $immutable_sha $name]
    if {$got ne $expected} {
        puts stderr "ERROR: immutable SHA mismatch $name got=$got expected=$expected"
        exit 4
    }
    puts "IMMUTABLE_OK $name $got"
}

set part_name xc7a100tcsg324-1
create_project -force a7lm04r5 $build_dir -part $part_name
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

puts "=== SYNTHESIS A7-LM-04R5 ==="
synth_design -top arty_a7_lm04_top -part $part_name -flatten_hierarchy rebuilt -directive PerformanceOptimized
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *pll*]
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *pll*]
write_checkpoint -force [file join $out_dir a7lm04r5_post_synth.dcp]
report_utilization -file [file join $out_dir a7lm04r5_utilization_synth.rpt]

puts "=== IMPLEMENT A7-LM-04R5 ==="
opt_design
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force [file join $out_dir a7lm04r5_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm04r5_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm04r5_utilization_route.rpt]

set paths [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $paths] == 0} {
    puts stderr "ERROR: no max-delay timing path returned"
    exit 5
}
set wns [get_property SLACK [lindex $paths 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.0} {
    puts stderr "ERROR: WNS=$wns, R5 LM-04 close requires >= 0.0 ns"
    exit 6
}
puts "LM05_TIMING_AUTHORIZED=[expr {$wns >= 0.20}]"

# Recheck immutables immediately before writing the sole R5 candidate path.
foreach name [dict keys $immutable_sha] {
    set got [sha256_file [file join $out_dir $name]]
    if {$got ne [dict get $immutable_sha $name]} {
        puts stderr "ERROR: immutable artifact changed during build: $name"
        exit 7
    }
}
set r5_bit [file join $out_dir arty_a7_lm04r5.bit]
write_bitstream -force $r5_bit
set r5_sha [sha256_file $r5_bit]
foreach old_sha [dict values $immutable_sha] {
    if {$r5_sha eq $old_sha} {
        puts stderr "ERROR: R5 bit SHA collides with a historical artifact"
        exit 8
    }
}
puts "A7_LM04R5_BUILD_PASS bitstream=$r5_bit SHA=$r5_sha WNS=$wns"
