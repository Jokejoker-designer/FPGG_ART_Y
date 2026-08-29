# write_e2r_atomic_sdone_probe_00_bit.tcl — bitstream only from routed DCP
# BUILD-ONLY. Do NOT program. Do NOT write F1x / SGO / B-FIX / R6 / frozen LM-06.
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-ATOMIC-SDONE-PROBE-00]
set dcp [file join $outdir e2r_post_route.dcp]
set out_bit [file join $outdir arty_a7_ng_native_v1_atomic_sdone_probe_00.bit]
set f1x_bit [file join $root results A7-NATIVE-GRAPH E2R-ATOMIC-DGR-PROBE-00 arty_a7_ng_native_v1_atomic_dgr_probe_00.bit]
set sgo_bit [file join $root results A7-NATIVE-GRAPH E2R-ATOMIC-SGO-PROBE-00 arty_a7_ng_native_v1_atomic_sgo_probe_00.bit]

if {![file exists $dcp]} {
  puts stderr "ERROR: missing $dcp"
  exit 2
}
if {[string match "*E2R-ATOMIC-DGR-PROBE-00*" $out_bit] || [string equal $out_bit $f1x_bit]} {
  puts stderr "REFUSE: would overwrite F1x bit"
  exit 3
}
if {[string match "*E2R-ATOMIC-SGO-PROBE-00*" $out_bit] || [string equal $out_bit $sgo_bit]} {
  puts stderr "REFUSE: would overwrite SGO bit"
  exit 3
}
if {[string match "*TINYGPT-SOC*" $out_bit] || [string match "*lm06*.bit" $out_bit]} {
  puts stderr "REFUSE: frozen LM-06 path"
  exit 3
}

open_checkpoint $dcp
# Exclusive file list omitted e2r_la_pmod_ja.xdc. Do not read it here.
# Waive ja-only NSTD-1/UCIO-1 (not LiteScope; no ILA).
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
write_bitstream -force $out_bit
set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
set bf [open [file join $outdir BIT_SHA256.txt] w]
puts $bf $bit_sha
close $bf
puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO"
exit 0
