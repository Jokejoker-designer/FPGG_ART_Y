# COFIT-00 CDC details only. PROGRAM=NO.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set dcp [file join $root results A7-NATIVE-GRAPH GROK-ORCH-00 P2-G1G5-FULLCHIP-COFIT-00 e2r_post_route.dcp]
open_checkpoint $dcp
report_cdc -details -file [file join $bag report_cdc_details_cofit.rpt]
report_cdc -file [file join $bag report_cdc_summary_cofit.rpt]
puts "COFIT_CDC_DUMP_DONE"
exit 0
