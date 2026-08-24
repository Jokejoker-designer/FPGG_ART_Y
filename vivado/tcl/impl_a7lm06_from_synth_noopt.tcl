# Fallback: impl A7-LM-06 from post-synth DCP with NO opt_design.
# Used only if RuntimeOptimized / default opt AV-crashes (Phase 3 Retarget).
# Writes arty_a7_lm06.bit ONLY.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set out_dir [file join $root_dir build out]
set dcp [file join $out_dir a7lm06_post_synth.dcp]
if {![file exists $dcp]} {
    puts stderr "ERROR: missing $dcp"
    exit 2
}

set_param general.maxThreads 4
open_checkpoint $dcp
puts "=== IMPLEMENT A7-LM-06 FROM SYNTH (NO OPT) ==="
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force [file join $out_dir a7lm06_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm06_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm06_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0} {
    puts stderr "ERROR: WNS=$wns (need >= 0 to write LM-06 bit)"
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
    arty_a7_lm05.bit 1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51]
foreach frozen {arty_a7_lm00.bit arty_a7_lm01.bit arty_a7_lm02.bit arty_a7_lm03.bit arty_a7_lm05.bit} {
    set fp [file join $out_dir $frozen]
    if {![file exists $fp]} {
        puts stderr "ERROR: refuse to write LM-06 without frozen $frozen"
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

set lm06_bit [file join $out_dir arty_a7_lm06.bit]
write_bitstream -force $lm06_bit
set lm06_sha [sha256_file $lm06_bit]
puts "A7_LM06_BUILD_PASS bitstream=$lm06_bit SHA=$lm06_sha WNS=$wns"
