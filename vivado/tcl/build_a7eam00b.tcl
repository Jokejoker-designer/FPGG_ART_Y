# A7-EAM-00B: board bitstream. Never write arty_a7_lm*.bit.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set build_dir  [file join $root_dir build vivado_a7eam00b]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-00]
file mkdir $build_dir
file mkdir $out_dir
file mkdir $res_dir

set part_name xc7a100tcsg324-1
set bitfile [file join $out_dir arty_a7_eam00b.bit]
if {[string match *arty_a7_lm* [file tail $bitfile]]} {
    puts stderr "REFUSE: EAM bit path must not be an LM name"
    exit 2
}

create_project -force a7eam00b $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl/eam a7eam00_pkg.sv] \
    [file join $root_dir rtl/eam eam_tdp256.sv] \
    [file join $root_dir rtl/eam eam_core.sv] \
    [file join $root_dir rtl/board uart_rx.sv] \
    [file join $root_dir rtl/board uart_tx.sv] \
    [file join $root_dir rtl/board sync_bits.sv] \
    [file join $root_dir rtl/eam eam00b_uart.sv] \
    [file join $root_dir rtl/board arty_a7_eam00b_top.sv]]
add_files -fileset constrs_1 -norecurse [list \
    [file join $root_dir constraints arty_a7_100.xdc] \
    [file join $root_dir constraints a7eam00b.xdc]]
set_property top arty_a7_eam00b_top [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH A7-EAM-00B ==="
synth_design -top arty_a7_eam00b_top -part $part_name -flatten_hierarchy rebuilt
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_checkpoint -force [file join $out_dir a7eam00b_post_synth.dcp]
report_utilization -file [file join $out_dir a7eam00b_utilization_synth.rpt]

set n_ramb36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n_ramb18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
puts "INFER ramb36=$n_ramb36 ramb18=$n_ramb18"

puts "=== IMPLEMENT A7-EAM-00B ==="
if {[catch {opt_design} err]} { puts "WARN: opt $err" }
place_design -directive ExtraTimingOpt
if {[catch {phys_opt_design -directive Explore} perr]} { puts "WARN: phys_opt $perr" }
route_design -directive Explore
write_checkpoint -force [file join $out_dir a7eam00b_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7eam00b_timing_route.rpt]
report_utilization -file [file join $out_dir a7eam00b_utilization_route.rpt]
report_drc -file [file join $out_dir a7eam00b_drc.rpt]

set cfgbvs [get_property CFGBVS [current_design]]
set cfgv   [get_property CONFIG_VOLTAGE [current_design]]
puts "CONFIG CFGBVS=$cfgbvs CONFIG_VOLTAGE=$cfgv"
if {$cfgbvs ne "VCCO" || $cfgv != 3.3} {
    puts stderr "ERROR: CFGBVS/CONFIG_VOLTAGE not Arty-A7 3.3V (got $cfgbvs $cfgv)"
    exit 3
}

set wns 0.0
set tns 0.0
set trpt [file join $out_dir a7eam00b_timing_route.rpt]
set fh [open $trpt r]
set txt [read $fh]
close $fh
if {[regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s+([-0-9.]+)\s+([-0-9.]+)} $txt -> wns_s tns_s]} {
    set wns $wns_s
    set tns $tns_s
}
puts "POST_ROUTE_WNS=$wns TNS=$tns"
if {$wns < 0.0 || abs($tns) > 0.0005} {
    puts stderr "ERROR: timing fail WNS=$wns TNS=$tns"
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
    arty_a7_lm03.bit C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1 \
    arty_a7_lm04r5.bit A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8 \
    arty_a7_lm05.bit 1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51 \
    arty_a7_lm06.bit 67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA \
    arty_a7_lm06c3.bit 222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6]
dict for {frozen exp} $frozen_sha {
    set fp [file join $out_dir $frozen]
    if {![file exists $fp]} {
        puts stderr "ERROR: missing frozen $fp"
        exit 5
    }
    set got [sha256_file $fp]
    if {$got ne $exp} {
        puts stderr "ERROR: frozen SHA mismatch $frozen got=$got exp=$exp"
        exit 6
    }
    puts "LOCKED_OK $frozen"
}

write_bitstream -force $bitfile
dict for {frozen exp} $frozen_sha {
    set got [sha256_file [file join $out_dir $frozen]]
    if {$got ne $exp} {
        puts stderr "ERROR: frozen mutated while writing EAM bit: $frozen"
        exit 7
    }
}

set bit_sha [sha256_file $bitfile]
set man [file join $res_dir build_manifest_00b.json]
set jf [open $man w]
puts $jf [format \
{{"bit":"build/out/arty_a7_eam00b.bit","sha256":"%s","wns_ns":%s,"tns_ns":%s,"cfgbvs":"%s","config_voltage":"%s","ramb36":%d,"ramb18":%d}} \
    $bit_sha $wns $tns $cfgbvs $cfgv $n_ramb36 $n_ramb18]
close $jf
puts "A7_EAM00B_BIT_PASS WNS=$wns TNS=$tns sha=$bit_sha CFGBVS=$cfgbvs"
