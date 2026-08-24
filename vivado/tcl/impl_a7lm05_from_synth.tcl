# Resume A7-LM-05 from post-synth DCP. Safer opt (RuntimeOptimized).
# Writes arty_a7_lm05.bit only. Does not touch 00-04 bits.
set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set out_dir [file join $root_dir build out]
set dcp [file join $out_dir a7lm05_post_synth.dcp]
if {![file exists $dcp]} {
    puts stderr "ERROR: missing $dcp"
    exit 2
}

set_param general.maxThreads 4
open_checkpoint $dcp
puts "=== IMPLEMENT A7-LM-05 FROM SYNTH (RuntimeOptimized opt) ==="
if {[catch {opt_design -directive RuntimeOptimized} err]} {
    puts "WARN: RuntimeOptimized opt failed ($err); retry default opt"
    if {[catch {opt_design} err2]} {
        puts stderr "ERROR: opt_design crashed twice: $err2"
        exit 3
    }
}
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force [file join $out_dir a7lm05_post_route.dcp]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm05_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm05_utilization_route.rpt]

set wns [get_property SLACK [lindex [get_timing_paths -quiet -delay_type max -max_paths 1] 0]]
puts "POST_ROUTE_WNS=$wns"
if {$wns < 0} {
    puts stderr "ERROR: WNS=$wns (need >= 0 to write LM-05 bit)"
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
        puts stderr "ERROR: refuse to write LM-05 without frozen $frozen"
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

set lm05_bit [file join $out_dir arty_a7_lm05.bit]
write_bitstream -force $lm05_bit
set lm05_sha [sha256_file $lm05_bit]
puts "A7_LM05_BUILD_PASS bitstream=$lm05_bit SHA=$lm05_sha WNS=$wns"
