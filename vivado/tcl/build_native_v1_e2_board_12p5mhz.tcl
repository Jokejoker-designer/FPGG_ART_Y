# E2 existence board — full SoC synth/impl/bitstream @ integrated (core on ui_clk).
# Lineage: E1-AB-COFIT-PARALLEL-00-CLOCK80 ab_post_route.dcp SHA 92A27DF7...
set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root results A7-NATIVE-GRAPH E2-BOARD-EXISTENCE-00]
set build_dir [file join $root build native_v1_board_parallel_e2_r3]
set out_bit [file join $root build out arty_a7_ng_native_v1_existence_00.bit]
file mkdir $outdir
file mkdir $build_dir
file mkdir [file join $root build out]

set ip_xci [file join $root vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
if {![file exists $ip_xci]} {
  puts stderr "ERROR: MIG IP missing"
  exit 2
}

foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e arty_a7_lm06} {
  if {[string match *$forbidden* [file tail $out_bit]]} {
    puts stderr "REFUSE: bit path collides with frozen artifact"
    exit 2
  }
}

create_project native_v1_e2_board $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property verilog_define {SYNTHESIS A7LM06_SNAP_LUTRAM_BIND} [current_fileset]

read_ip $ip_xci
set mig_ip [get_files $ip_xci]
generate_target all $mig_ip
# NOTE: XCI sub-design alone does not elaborate mig_7series_0 in Vivado 2026.1 batch
# (probe: module not found without explicit RTL). Glob duplicates 102 CRITICAL warnings
# but is required for synthesis; do not add_files AND read_ip on same paths twice — only glob.
set mig_rtl [concat \
  [glob -nocomplain [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
  [glob -nocomplain [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]

set srcs [list \
  [file join $root rtl/board/sync_bits.sv] \
  [file join $root rtl/board/uart_tx.sv] \
  [file join $root rtl/board/clkdiv8.sv] \
  [file join $root rtl/board/clkdiv2.sv] \
  [file join $root rtl/board/a7ng_ddr_soa_boot.sv] \
  [file join $root rtl/ddr/clk_arty_ddr.sv] \
  [file join $root rtl/ddr/mig_native_wrap.sv] \
  [file join $root rtl/ddr/ddr_tile_dma.sv] \
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
  [file join $root rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv] \
  {*}$mig_rtl]

add_files -norecurse $srcs

add_files -fileset constrs_1 -norecurse [list \
  [file join $root constraints arty_a7_100.xdc] \
  [file join $root constraints a7ng03_cdc.xdc] \
  $mig_xdc]

set_property top arty_a7_ng_native_v1_ab_soc_top [current_fileset]
set_property generic {SIM_FULL=0} [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "=== SYNTH E2-BOARD-EXISTENCE-00 ==="
synth_design -top arty_a7_ng_native_v1_ab_soc_top -part xc7a100tcsg324-1 -generic SIM_FULL=0 -flatten_hierarchy rebuilt
catch {set_clock_groups -asynchronous -group [get_clocks -quiet sys_clk_pin] -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm).* }]}
write_checkpoint -force [file join $outdir e2_post_synth.dcp]
report_utilization -hierarchical -file [file join $outdir e2_util_synth_hier.rpt]
report_utilization -file [file join $outdir e2_util_synth.rpt]

# Pre-place gate: TILE branch + u_ab RAMB36 ~96 (not FULL/320)
set hier_rpt [file join $outdir e2_util_synth_hier.rpt]
set hf [open $hier_rpt r]
set hier_text [read $hf]
close $hf
set gate_fail 0
if {[string match *FULL.u_full* $hier_text]} {
  puts stderr "GATE_FAIL: u_w shows FULL branch (expected TILE)"
  set gate_fail 1
}
if {![string match *TILE.u_bank* $hier_text]} {
  puts stderr "GATE_FAIL: u_w TILE.u_bank not found in synth hier"
  set gate_fail 1
}
set u_ab_ramb36 [llength [get_cells -quiet -hierarchical -filter {NAME =~ */u_ab/* && REF_NAME =~ RAMB36*}]]
if {$u_ab_ramb36 == 0 && [regexp {\|\s+u_ab\s+\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|\s+(\d+)\s+\|} $hier_text -> u_ab_ramb36]} {
  puts "PREPLACE_GATE u_ab_ramb36=$u_ab_ramb36 (from hier rpt RAMB36 col)"
} else {
  puts "PREPLACE_GATE u_ab_ramb36=$u_ab_ramb36 (from get_cells)"
}
if {$u_ab_ramb36 > 120} {
  puts stderr "GATE_FAIL: u_ab RAMB36=$u_ab_ramb36 (expected ~96, not 320)"
  set gate_fail 1
}
if {$gate_fail} {
  puts stderr "STOP: pre-place BRAM gate failed — no place/route"
  exit 3
}
puts "PREPLACE_GATE PASS u_w=TILE u_ab_ramb36=$u_ab_ramb36"

puts "=== IMPLEMENT E2-BOARD-EXISTENCE-00 ==="
if {[catch {opt_design} err]} { puts "WARN opt $err" }
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN phys_opt $perr" }
route_design
if {[catch {phys_opt_design -directive Explore} perr2]} { puts "WARN phys_opt2 $perr2" }

report_timing_summary -delay_type min_max -max_paths 20 -file [file join $outdir e2_timing_route.rpt]
report_utilization -hierarchical -file [file join $outdir e2_util_hier.rpt]
report_utilization -file [file join $outdir e2_util_route.rpt]
report_route_status -file [file join $outdir e2_route_status.rpt]
write_checkpoint -force [file join $outdir e2_post_route.dcp]

set wns_p [get_timing_paths -quiet -delay_type max -max_paths 1]
set whs_p [get_timing_paths -quiet -delay_type min -max_paths 1]
set wns NA; set whs NA; set tns NA; set ths NA
if {[llength $wns_p] > 0} { set wns [get_property SLACK [lindex $wns_p 0]] }
if {[llength $whs_p] > 0} { set whs [get_property SLACK [lindex $whs_p 0]] }
set tsum [report_timing_summary -return_string -no_header -no_detailed_paths]
if {[regexp {WNS\(ns\)\s+TNS\(ns\)\s+WHS\(ns\)\s+THS\(ns\)\s*\n\s*([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)} $tsum -> _wns _tns _whs _ths]} {
  set tns $_tns
  set ths $_ths
}

set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set eq36 [expr {$n36 + int(ceil($n18 / 2.0))}]
set dsps [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

set mf [open [file join $outdir e2_postroute_metrics.txt] w]
puts $mf "E1_DCP_SHA=92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA"
puts $mf "core_note=ui_clk_integrated E1_OOC_80ns_lineage SIM_FULL=0"
puts $mf "ramb36=$n36 ramb18=$n18 eq36=$eq36 dsps=$dsps WNS=$wns TNS=$tns WHS=$whs THS=$ths"
close $mf

set bit_ok 1
if {$n36 > 135} {
  puts stderr "GATE_FAIL: post-route RAMB36=$n36 > 135 — no bitstream"
  set bit_ok 0
}
if {$wns < 0 || $tns != 0} {
  puts stderr "GATE_FAIL: timing WNS=$wns TNS=$tns — no bitstream"
  set bit_ok 0
}
if {$bit_ok} {
  write_bitstream -force $out_bit
  file copy -force $out_bit [file join $outdir arty_a7_ng_native_v1_existence_00.bit]
} else {
  puts "SKIP_BITSTREAM timing_or_bram_gate_failed"
}

puts "E2_BIT=$out_bit WNS=$wns TNS=$tns BRAM36=$n36 bit_ok=$bit_ok"
if {!$bit_ok} { exit 5 }
exit 0
