# Finalize A7-LM-04 R5 from its clean routed checkpoint.
# Contract gate: WNS >= 0 and TNS = 0. WNS >= +0.20 is reported separately
# for LM-05 timing authorization and is not required to close LM-04.
# Run:
#   C:/2026.1/Vivado/bin/vivado.bat -mode batch -notrace \
#     -source vivado/tcl/finalize_a7lm04r5_from_route.tcl \
#     -log build/a7lm04r5_finalize.log -journal build/a7lm04r5_finalize.jou
# Output: build/out/arty_a7_lm04r5.bit. Next: freeze build manifest.

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir ../..]]
set out_dir [file join $root_dir build out]
set dcp [file join $out_dir a7lm04r5_post_route.dcp]
if {![file exists $dcp]} { puts stderr "ERROR: missing $dcp"; exit 2 }
open_checkpoint $dcp
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out_dir a7lm04r5_timing_route.rpt]
report_utilization -file [file join $out_dir a7lm04r5_utilization_route.rpt]

set paths [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $paths] == 0} { puts stderr "ERROR: no max-delay timing path"; exit 3 }
set wns [get_property SLACK [lindex $paths 0]]
if {$wns < 0.0} { puts stderr "ERROR: LM-04 timing failed WNS=$wns"; exit 4 }

proc sha256_file {path} {
    set escaped [string map {' ''} $path]
    set out [exec powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '$escaped').Hash"]
    return [string toupper [string trim $out]]
}
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
    if {![file exists $path]} { puts stderr "ERROR: missing immutable $name"; exit 5 }
    set got [sha256_file $path]
    if {$got ne [dict get $immutable_sha $name]} {
        puts stderr "ERROR: immutable SHA mismatch $name"
        exit 6
    }
}

set bit [file join $out_dir arty_a7_lm04r5.bit]
write_bitstream -force $bit
set bit_sha [sha256_file $bit]
if {[lsearch -exact [dict values $immutable_sha] $bit_sha] >= 0} {
    puts stderr "ERROR: R5 bit SHA collides with historical artifact"
    exit 7
}
puts "A7_LM04R5_FINALIZE_PASS bitstream=$bit SHA=$bit_sha WNS=$wns LM05_TIMING_AUTHORIZED=[expr {$wns >= 0.20}]"
