# Write bitstream from already-routed DCP. Timing met (WNS 0.651).
# CDC parser counted 5 User-Ignored (async groups / MIG false path), not unconstrained.
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-CORE-START-RST-PROBE-00]
set dcp [file join $outdir e2r_post_route.dcp]
if {![file exists $dcp]} {
  puts stderr "ERROR: missing $dcp"
  exit 2
}
open_checkpoint $dcp
set bitdir [file join $root build out]
file mkdir $bitdir
set out_bit [file join $bitdir arty_a7_ng_native_v1_core_start_rst_probe_00.bit]
write_bitstream -force $out_bit
file copy -force $out_bit [file join $outdir arty_a7_ng_native_v1_core_start_rst_probe_00.bit]
set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
set bf [open [file join $outdir BIT_SHA256.txt] w]
puts $bf $bit_sha
close $bf
puts "BIT_OK path=$out_bit sha256=$bit_sha"
exit 0
