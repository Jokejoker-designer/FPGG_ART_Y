# No-bit post-route of a7ng_native_v1_ab_core SIM_FULL=0 + snap LUTRAM bind.
# E1-AB-COFIT-PARALLEL-00-CLOCK65 falsifier: 65ns period (~15.4 MHz).
# Stops after route. No write_bitstream.
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E1-AB-COFIT-PARALLEL-00-CLOCK65]
file mkdir $outdir
set build_dir [file join $root build native_v1_board_parallel_e1_65ns]
file mkdir $build_dir
create_project native_v1_ab $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set srcs [list \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/native_graph/memory/a7ng_lm06_snap_lutram.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv] \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory/a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_array.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_lane.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_wavefront_global.sv] \
  [file join $root rtl/native_graph/topk/a7ng_ng02_core.sv] \
  [file join $root rtl/native_graph/frontier/a7ng_frontier_buckets.sv] \
  [file join $root rtl/native_graph/memory/a7ng_ddr_soa_axi_bridge.sv] \
  [file join $root rtl/native_graph/memory/a7ng_soa_plane_engine.sv] \
  [file join $root rtl/native_graph/memory/a7ng_soa_plane_fetch.sv] \
  [file join $root rtl/native_graph/memory/a7ng_axi_read_stream.sv] \
  [file join $root rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv] \
  [file join $root rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_lm_graph_arb.sv] \
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv] \
]
add_files -norecurse $srcs
set_property top a7ng_native_v1_ab_core [current_fileset]
set_property generic {SIM_FULL=0} [get_filesets sources_1]
set_property verilog_define {SYNTHESIS A7LM06_SNAP_LUTRAM_BIND} [current_fileset]
update_compile_order -fileset sources_1
# OOC: candidate has too many ports for Artix-7 IOB; this is a physical
# resource/timing candidate, not a pinout bitstream.
synth_design -mode out_of_context -top a7ng_native_v1_ab_core -part xc7a100tcsg324-1 -generic SIM_FULL=0
create_clock -name clk -period 65.000 [get_ports clk]
write_checkpoint -force [file join $outdir ab_post_synth.dcp]
report_utilization -hierarchical -file [file join $outdir ab_util_synth_hier.rpt]
report_utilization -file [file join $outdir ab_util_synth.rpt]
set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set eq36 [expr {$n36 + int(ceil($n18 / 2.0))}]
puts "AB_POSTSYNTH ramb36=$n36 ramb18=$n18 eq36=$eq36"
set route_ok 1
if {[catch {opt_design} e]} { puts "AB_OPT_ERR $e"; set route_ok 0 }
if {$route_ok && [catch {place_design} e]} { puts "AB_PLACE_ERR $e"; set route_ok 0 }
if {$route_ok && [catch {route_design} e]} { puts "AB_ROUTE_ERR $e"; set route_ok 0 }
if {$route_ok} {
  write_checkpoint -force [file join $outdir ab_post_route.dcp]
  report_utilization -hierarchical -file [file join $outdir ab_util_hier.rpt]
  report_utilization -file [file join $outdir ab_util_route.rpt]
  report_timing_summary -delay_type min_max -max_paths 20 -file [file join $outdir ab_timing_route.rpt]
  report_route_status -file [file join $outdir ab_route_status.rpt]
} else {
  report_utilization -hierarchical -file [file join $outdir ab_util_hier.rpt]
  report_utilization -file [file join $outdir ab_util_placefail.rpt]
}
set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set eq36 [expr {$n36 + int(ceil($n18 / 2.0))}]
set luts [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ LUT*}]]
set lutram [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAM* && REF_NAME !~ RAMB*}]]
set ffs [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ FD*}]]
set dsps [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]
set wns_p [get_timing_paths -quiet -delay_type max -max_paths 1]
set whs_p [get_timing_paths -quiet -delay_type min -max_paths 1]
set wns NA
set whs NA
if {[llength $wns_p] > 0} { set wns [get_property SLACK [lindex $wns_p 0]] }
if {[llength $whs_p] > 0} { set whs [get_property SLACK [lindex $whs_p 0]] }
set mf [open [file join $outdir ab_postroute_metrics.txt] w]
puts $mf "clock_period_ns=65.000 ramb36=$n36 ramb18=$n18 eq36=$eq36 luts=$luts lutram=$lutram ffs=$ffs dsps=$dsps WNS=$wns WHS=$whs route_ok=$route_ok"
close $mf
puts "AB_POSTROUTE clock_period_ns=65.000 ramb36=$n36 ramb18=$n18 eq36=$eq36 luts=$luts lutram=$lutram ffs=$ffs dsps=$dsps WNS=$wns WHS=$whs route_ok=$route_ok"
# no write_bitstream
close_project
if {$route_ok} { exit 0 } else { exit 4 }
