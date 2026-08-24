# A7-LM-06 ILA debug bit. Writes arty_a7_lm06_ila.bit + .ltx ONLY.
# Does not overwrite C1 arty_a7_lm06.bit or frozen 00-05.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $root_dir build vivado_a7lm06_ila]
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
create_project -force a7lm06_ila $build_dir -part $part_name
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
    [file join $root_dir rtl lm a7lm06_pkg.sv] \
    [file join $root_dir rtl lm isqrt32.sv] \
    [file join $root_dir rtl lm floordiv_s48.sv] \
    [file join $root_dir rtl lm weight_bram803k.sv] \
    [file join $root_dir rtl lm weight_bram_tdp8.sv] \
    [file join $root_dir rtl lm weight_tile803k.sv] \
    [file join $root_dir rtl lm act_ram128k16.sv] \
    [file join $root_dir rtl lm snap_ram4k16.sv] \
    [file join $root_dir rtl lm tiny_gpt803k_core.sv] \
    [file join $root_dir rtl lm lm06_persist.sv] \
    [file join $root_dir rtl board arty_a7_lm06_top.sv] \
    {*}$mig_rtl]

add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints arty_a7_lm06.xdc] \
    [file join $root_dir constraints a7lm01_cdc.xdc] \
    $mig_xdc]

set_property top arty_a7_lm06_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTHESIS A7-LM-06 ILA ==="
synth_design -top arty_a7_lm06_top -part $part_name -flatten_hierarchy rebuilt -directive RuntimeOptimized
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *pll*]
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *pll*]
write_checkpoint -force [file join $out_dir a7lm06_ila_post_synth.dcp]

puts "=== IMPLEMENT A7-LM-06 DBG (no ILA IP; BASIC license) ==="
if {[catch {opt_design -directive RuntimeOptimized} err]} {
    puts "WARN: RuntimeOptimized opt failed ($err); retry default opt"
    if {[catch {opt_design} err2]} {
        puts "WARN: default opt failed ($err2); continue"
    }
}
place_design -directive ExtraTimingOpt
phys_opt_design -directive Explore
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7lm06_ila_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm06_ila_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm06_ila_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0} {
    puts "WARN: ILA WNS=$wns (debug bit still written)"
}

proc sha256_file {path} {
    set out [exec powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '$path').Hash"]
    return [string toupper [string trim $out]]
}

set c1_bit [file join $out_dir arty_a7_lm06.bit]
set c1_copy [file join $out_dir arty_a7_lm06c1_hw_partial.bit]
set c1_sha 67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA
foreach p [list $c1_bit $c1_copy] {
    if {![file exists $p]} {
        puts stderr "ERROR: missing C1 lock file $p"
        exit 5
    }
    set got [sha256_file $p]
    if {$got ne $c1_sha} {
        puts stderr "ERROR: C1 SHA changed $p got=$got exp=$c1_sha"
        exit 6
    }
    puts "C1_LOCKED_OK $p"
}

set frozen_sha [dict create \
    arty_a7_lm00.bit 449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783 \
    arty_a7_lm01.bit 96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8 \
    arty_a7_lm02.bit 7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4 \
    arty_a7_lm03.bit C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1 \
    arty_a7_lm05.bit 1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51]
foreach frozen {arty_a7_lm00.bit arty_a7_lm01.bit arty_a7_lm02.bit arty_a7_lm03.bit arty_a7_lm05.bit} {
    set fp [file join $out_dir $frozen]
    set got [sha256_file $fp]
    set exp [dict get $frozen_sha $frozen]
    if {$got ne $exp} {
        puts stderr "ERROR: frozen SHA mismatch $frozen got=$got exp=$exp"
        exit 6
    }
}

set ila_bit [file join $out_dir arty_a7_lm06_ila.bit]
write_bitstream -force $ila_bit
set ila_sha [sha256_file $ila_bit]
set still [sha256_file $c1_bit]
if {$still ne $c1_sha} {
    puts stderr "ERROR: C1 bit mutated during ILA write"
    exit 7
}
puts "A7_LM06_ILA_BUILD_PASS bitstream=$ila_bit SHA=$ila_sha WNS=$wns"
