# GO-GRANT-SOA-SOC-00 — exclusive post-route (1-cycle D_GO pulse tile)
# PROGRAM=NO. No open_hw_manager. No qstar_* on SoC. No leftover LONGBOOT/two-pass bit.
# SIM_FULL=0. 12.5 MHz / 80 ns existence clock. BRAM36<=135 WNS>=0 TNS=0.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set_param general.maxThreads 8
puts "VIVADO maxThreads=[get_param general.maxThreads]"
puts "ROOT=$root"
puts "BAG=$bag"

if {![string match "*arty-a7-online-lm-grok-orch-00" $root]} {
  puts stderr "REFUSE: root is not grok-orch-00 worktree root=$root"
  exit 3
}
if {[string match "*arty-a7-online-lm-board*" $root]} {
  puts stderr "REFUSE: board worktree root=$root"
  exit 3
}
if {[string match "*arty-a7-online-lm-close664*" $root]} {
  puts stderr "REFUSE: close664 worktree root=$root"
  exit 3
}
if {![string match "*GO-GRANT-SOA-SOC-00*" $bag]} {
  puts stderr "REFUSE: tcl not in GO-GRANT-SOA-SOC-00 bag bag=$bag"
  exit 3
}

set outdir $bag
set build_dir [file join $root build go_grant_soa_soc_00]
file mkdir $outdir
file mkdir $build_dir

if {[string match "*E2R-UART-HOLD-LONGBOOT*" $outdir] ||
    [string match "*E2R-EMB-TWO-PASS*" $outdir] ||
    [string match "*close664*" $outdir] ||
    [string match "*arty-a7-online-lm-board*" $outdir] ||
    [string equal $build_dir [file join $root build out]]} {
  puts stderr "REFUSE: leftover/LONGBOOT/board path outdir=$outdir build_dir=$build_dir"
  exit 3
}

set out_bit [file join $outdir arty_a7_ng_native_v1_grok_orch_grant_soa_00.bit]
set dcp_path [file join $outdir e2r_post_route.dcp]
set timing_rpt [file join $outdir report_timing_summary.rpt]
set util_rpt [file join $outdir report_utilization_route.rpt]
set cdc_rpt [file join $outdir report_cdc.rpt]
set cdc_cls [file join $outdir CDC_CLASSIFY.txt]
set route_rpt [file join $outdir report_route_status.rpt]
puts "EXEC: exclusive grok-orch existence bag TCL PROGRAM=NO no open_hw_manager"
puts "BIT_PATH=$out_bit"

foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e arty_a7_lm06 longboot 9DC0F8DF 15B0E502} {
  if {[string match *$forbidden* [string tolower [file tail $out_bit]]]} {
    puts stderr "REFUSE: bit path collides with frozen/leftover artifact"
    exit 3
  }
}

set cdc_sv [file nativename [file join $root rtl board a7ng_wdma_cdc.sv]]
set top_sv [file nativename [file join $root rtl board arty_a7_ng_native_v1_ab_soc_top.sv]]
set tile_sv [file nativename [file join $root rtl lm weight_tile803k.sv]]
set dma_sv [file nativename [file join $root rtl ddr ddr_tile_dma.sv]]
set core_sv [file nativename [file join $root rtl lm tiny_gpt803k_core.sv]]
set cdc_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$cdc_sv' | Select-Object -ExpandProperty Hash"]]
set top_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$top_sv' | Select-Object -ExpandProperty Hash"]]
set tile_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$tile_sv' | Select-Object -ExpandProperty Hash"]]
set dma_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$dma_sv' | Select-Object -ExpandProperty Hash"]]
set core_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$core_sv' | Select-Object -ExpandProperty Hash"]]
puts "CANDIDATE_CDC_SHA256=$cdc_sha"
puts "CANDIDATE_TOP_SHA256=$top_sha"
puts "CANDIDATE_TILE_SHA256=$tile_sha"
puts "CANDIDATE_DMA_SHA256=$dma_sha"
puts "CANDIDATE_CORE_SHA256=$core_sha"
if {$cdc_sha ne "5AF2FBDA5E9D2E0F1527BD9E89D6935CDC7722BD775DCE0870683C215A06539D"} {
  puts stderr "STOP: CDC SHA drifted $cdc_sha"
  exit 3
}
if {$top_sha ne "8E7EAD59065E7E1F17A69B04E5A46A586B41C9EE4938E84A527C275001E1BAE2"} {
  puts stderr "STOP: top SHA drifted $top_sha"
  exit 3
}
if {$tile_sha ne "06F62A3A71E00B2A8F8B6D7277488544ABD1556B03F6FE88165E24EC6A4CB430"} {
  puts stderr "STOP: tile SHA drifted $tile_sha"
  exit 3
}
if {$dma_sha ne "20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5"} {
  puts stderr "STOP: dma SHA drifted $dma_sha"
  exit 3
}
if {$core_sha ne "355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7"} {
  puts stderr "STOP: core SHA drifted $core_sha"
  exit 3
}

set ip_xci [file join $root vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
if {![file exists $ip_xci]} {
  puts stderr "ERROR: MIG IP missing"
  exit 2
}

create_project go_grant_soa_soc_00 $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property verilog_define {SYNTHESIS A7LM06_SNAP_LUTRAM_BIND} [current_fileset]

read_ip $ip_xci
set mig_ip [get_files $ip_xci]
generate_target all $mig_ip
set mig_rtl [concat \
  [glob -nocomplain [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*.v]] \
  [glob -nocomplain [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/rtl/*/*.v]]]

set srcs [list \
  [file join $root rtl/board/sync_bits.sv] \
  [file join $root rtl/board/uart_tx.sv] \
  [file join $root rtl/board/clk_core_12p5.sv] \
  [file join $root rtl/board/a7ng_axi_read_cdc.sv] \
  [file join $root rtl/board/a7ng_wdma_cdc.sv] \
  [file join $root rtl/board/a7ng_ddr_wmem_boot.sv] \
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

foreach s $srcs {
  if {[string match "*qstar*" [string tolower $s]]} {
    puts stderr "REFUSE: qstar source in existence SoC $s"
    exit 3
  }
}

add_files -norecurse $srcs
add_files -fileset constrs_1 -norecurse [list \
  [file join $root constraints arty_a7_100.xdc] \
  [file join $root constraints a7ng03_cdc.xdc] \
  [file join $root constraints e2r_core_clk.xdc] \
  [file join $root constraints arty_a7_qspi.xdc] \
  $mig_xdc]

set_property top arty_a7_ng_native_v1_ab_soc_top [current_fileset]
set_property generic {SIM_FULL=0} [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "=== SYNTH GO-GRANT-SOA-SOC-00 ==="
synth_design -top arty_a7_ng_native_v1_ab_soc_top -part xc7a100tcsg324-1 -generic SIM_FULL=0 -flatten_hierarchy rebuilt
write_checkpoint -force [file join $outdir e2r_post_synth.dcp]
report_utilization -hierarchical -file [file join $outdir report_utilization_hier.rpt]
report_utilization -file [file join $outdir report_utilization.rpt]
report_clocks -file [file join $outdir report_clocks.rpt]

set hier_rpt [file join $outdir report_utilization_hier.rpt]
set hf [open $hier_rpt r]
set hier_text [read $hf]
close $hf
set u_ab_ramb36 0
if {[regexp {\|\s+u_ab\s+\|[^\n]*\|\s+(\d+)\s+\|} $hier_text -> u_ab_ramb36]} {
  puts "PREPLACE_GATE u_ab_ramb36=$u_ab_ramb36"
} else {
  set u_ab_ramb36 [llength [get_cells -quiet -hierarchical -filter {NAME =~ */u_ab/* && REF_NAME =~ RAMB36*}]]
}
if {$u_ab_ramb36 > 120} {
  puts stderr "GATE_FAIL: u_ab RAMB36=$u_ab_ramb36"
  exit 3
}

puts "=== IMPLEMENT GO-GRANT-SOA-SOC-00 ==="
source [file join $root vivado tcl e2r_core_clk_constraints.tcl]
e2r_apply_core_clk_constraints
place_design
if {[catch {phys_opt_design} perr]} { puts "WARN phys_opt $perr" }
route_design
if {[catch {phys_opt_design -directive Explore} perr2]} { puts "WARN phys_opt2 $perr2" }

report_timing_summary -delay_type min_max -max_paths 20 -file $timing_rpt
report_utilization -hierarchical -file [file join $outdir report_utilization_route_hier.rpt]
report_utilization -file $util_rpt
report_clocks -file [file join $outdir report_clocks_route.rpt]
report_clock_interaction -delay_type min_max -file [file join $outdir report_clock_interaction.rpt]
report_cdc -file $cdc_rpt
report_route_status -file $route_rpt
write_checkpoint -force $dcp_path

proc e2r_domain_timing {clk_name} {
  set clk_obj [get_clocks -quiet $clk_name]
  if {[llength $clk_obj] == 0} { return [list NA NA] }
  set paths [get_timing_paths -quiet -from $clk_obj -to $clk_obj -max_paths 1 -nworst 1 -setup]
  if {[llength $paths] == 0} { return [list NA NA] }
  set wns [get_property SLACK $paths]
  set tns 0
  if {$wns < 0} {
    set fail [get_timing_paths -quiet -from $clk_obj -to $clk_obj -max_paths 1000 -nworst 1 -setup -slack_lesser_than 0]
    foreach p $fail {
      set tns [expr {$tns + [get_property SLACK $p]}]
    }
  }
  return [list $wns $tns]
}

proc e2r_is_clkgen_falsepath {src dst line} {
  if {![string match "*False Path*" $line]} { return 0 }
  if {$src ne "c166_raw"} { return 0 }
  if {$dst eq "clk_div2_bufg_in"} { return 1 }
  if {$dst eq "clk_pll_i"} { return 1 }
  if {$dst eq "mmcm_ps_clk_bufg_in"} { return 1 }
  return 0
}

proc e2r_classify_cdc {cdc_text cls_path} {
  set cf [open $cls_path w]
  puts $cf "GO-GRANT-SOA-SOC-00 CDC classify (each Unsafe>0 row)"
  set n_clkgen 0
  set n_cand 0
  set n_rows 0
  foreach line [split $cdc_text "\n"] {
    if {![regexp {^\s*(Critical|Warning|Info)\s+(\S+)\s+(\S+)} $line -> sev src dst]} { continue }
    if {![regexp {\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$} $line -> ep safe uns unk nar]} { continue }
    if {$uns == 0} { continue }
    incr n_rows
    set cls CANDIDATE_LOGIC
    if {[e2r_is_clkgen_falsepath $src $dst $line]} {
      set cls CLOCK_GEN_FALSEPATH
      incr n_clkgen $uns
    } else {
      incr n_cand $uns
    }
    set row "CDC_UNSAFE sev=$sev src=$src dst=$dst uns=$uns class=$cls"
    puts $row
    puts $cf $row
  }
  puts $cf "SUMMARY rows_unsafe=$n_rows clkgen_falsepath_endpoints=$n_clkgen candidate_logic_endpoints=$n_cand"
  close $cf
  puts "CDC_CLASSIFY rows_unsafe=$n_rows clkgen_falsepath=$n_clkgen candidate_logic=$n_cand"
  return [list $n_clkgen $n_cand $n_rows]
}

set tsum [report_timing_summary -return_string -no_header -no_detailed_paths]
set wns NA; set tns NA; set whs NA; set ths NA
if {[regexp {WNS\(ns\)\s+TNS\(ns\)\s+WHS\(ns\)\s+THS\(ns\)\s*\n\s*([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)} $tsum -> _wns _tns _whs _ths]} {
  set wns $_wns
  set tns $_tns
  set whs $_whs
  set ths $_ths
}
puts "TIMING_PARSE WNS=$wns TNS=$tns WHS=$whs THS=$ths"

set core_wns NA; set core_tns NA; set ui_wns NA; set ui_tns NA
if {[llength [get_clocks -quiet core_clk]] > 0} {
  lassign [e2r_domain_timing core_clk] core_wns core_tns
} elseif {[llength [get_clocks -quiet core_raw]] > 0} {
  lassign [e2r_domain_timing core_raw] core_wns core_tns
}
if {[llength [get_clocks -quiet clk_pll_i]] > 0} {
  lassign [e2r_domain_timing clk_pll_i] ui_wns ui_tns
}

set n36 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB36*}]]
set n18 [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ RAMB18*}]]
set dsps [llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ DSP*}]]

set cdc_cand 0
if {[file exists $cdc_rpt]} {
  set cf [open $cdc_rpt r]
  set cdc_text [read $cf]
  close $cf
  lassign [e2r_classify_cdc $cdc_text $cdc_cls] cdc_clkgen cdc_cand cdc_rows
}

set gate_pass 1
if {$n36 > 135} { puts stderr "GATE_FAIL BRAM36=$n36"; set gate_pass 0 }
if {$cdc_cand != 0} { puts "FINDING candidate_logic_cdc=$cdc_cand (not bitstream skip; u_wdma_rel_sync)" }
if {$wns == "NA"} {
  set tf [open $timing_rpt r]
  set ttxt [read $tf]
  close $tf
  set seen 0
  foreach line [split $ttxt "\n"] {
    if {[string match "*Design Timing Summary*" $line]} { set seen 1 }
    if {$seen && [regexp {^[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+)} $line -> _wns _tns _whs _ths]} {
      set wns $_wns
      set tns $_tns
      set whs $_whs
      set ths $_ths
      puts "TIMING_PARSE_FILE WNS=$wns TNS=$tns WHS=$whs THS=$ths"
      break
    }
  }
}
if {$wns != "NA" && $wns < 0} { puts stderr "GATE_FAIL WNS=$wns"; set gate_pass 0 }
if {$tns != "NA" && $tns != 0} { puts stderr "GATE_FAIL TNS=$tns"; set gate_pass 0 }
if {$core_wns != "NA" && $core_wns < 0} { puts stderr "GATE_FAIL core WNS=$core_wns"; set gate_pass 0 }
if {$ui_wns != "NA" && $ui_wns < 0} { puts stderr "GATE_FAIL ui WNS=$ui_wns"; set gate_pass 0 }

set mf [open [file join $outdir e2r_metrics.txt] w]
puts $mf "GATE=GO-GRANT-SOA-SOC-00 PROGRAM=NO"
puts $mf "ramb36=$n36 ramb18=$n18 dsps=$dsps"
puts $mf "WNS=$wns TNS=$tns WHS=$whs THS=$ths"
puts $mf "core_WNS=$core_wns core_TNS=$core_tns ui_WNS=$ui_wns ui_TNS=$ui_tns"
puts $mf "cdc_cand=$cdc_cand gate_pass=$gate_pass"
puts $mf "CDC=$cdc_sha"
puts $mf "TOP=$top_sha"
puts $mf "CORE=$core_sha"
close $mf

puts "GO_GRANT_SOA_SOC_00_METRICS ramb36=$n36 WNS=$wns TNS=$tns core_WNS=$core_wns ui_WNS=$ui_wns cdc_cand=$cdc_cand gate_pass=$gate_pass"

if {$gate_pass} {
  puts "=== WRITE_BITSTREAM GO-GRANT-SOA-SOC-00 PROGRAM=NO ==="
  if {[catch {set_property SEVERITY {Warning} [get_drc_checks NSTD-1]} w1]} { puts "WARN nstd $w1" }
  if {[catch {set_property SEVERITY {Warning} [get_drc_checks UCIO-1]} w2]} { puts "WARN ucio $w2" }
  write_bitstream -force $out_bit
  set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
  set bf [open [file join $outdir BIT_SHA256.txt] w]
  puts $bf $bit_sha
  close $bf
  puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO"
} else {
  puts "SKIP_BITSTREAM gate_pass=0 PROGRAM=NO"
  exit 5
}
puts "GO_GRANT_SOA_SOC_00_IMPL_PASS PROGRAM=NO"
exit 0
