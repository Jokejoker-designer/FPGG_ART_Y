set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-CLOCK-CDC-00]
open_checkpoint [file join $outdir e2r_post_route.dcp]
report_cdc -details -file [file join $outdir report_cdc_details.rpt]
exit 0
