# Continue A7-LM-04R3 from a7lm04r3_post_synth.dcp. Does not overwrite FAIL or R2 bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set out_dir [file join $root_dir build out]
set dcp [file join $out_dir a7lm04r3_post_synth.dcp]
if {![file exists $dcp]} { puts stderr "missing $dcp"; exit 2 }
open_checkpoint $dcp

set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *pll*]
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks sys_clk_pin] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks -quiet clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks -quiet clk50] -from [get_clocks -quiet *pll*]

puts "=== IMPLEMENT A7-LM-04R3 FROM SYNTH ==="
opt_design
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force [file join $out_dir a7lm04r3_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm04r3_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm04r3_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0.20} {
    puts stderr "ERROR: WNS=$wns (need >= +0.20)"
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
    set got [sha256_file $fp]
    set exp [dict get $frozen_sha $frozen]
    if {$got ne $exp} {
        puts stderr "ERROR: frozen SHA mismatch $frozen"
        exit 6
    }
}
set fail_bit [file join $out_dir arty_a7_lm04.bit]
set fail_sha [sha256_file $fail_bit]
if {$fail_sha ne "0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2"} {
    puts stderr "ERROR: FAIL candidate bit mutated"
    exit 7
}
set r2_bit [file join $out_dir arty_a7_lm04r.bit]
set r2_sha [sha256_file $r2_bit]
if {$r2_sha ne "6BED0DE83922B45BABBD8D2DD0F46F0F469474CB9F0A8A1DF96D1421817EF6B9"} {
    puts stderr "ERROR: R2 validation bit mutated"
    exit 8
}
set r3_bit [file join $out_dir arty_a7_lm04r3.bit]
write_bitstream -force $r3_bit
set r3_sha [sha256_file $r3_bit]
if {$r3_sha eq $fail_sha || $r3_sha eq $r2_sha} {
    puts stderr "ERROR: r3 bit SHA collides with FAIL or R2"
    exit 9
}
puts "A7_LM04R3_BUILD_PASS bitstream=$r3_bit SHA=$r3_sha WNS=$wns"
