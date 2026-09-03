# P2-GATE14-C1-UART-RX-COMMAND-01 - PHYS=4. LABEL=MINHEAP. PROGRAM=NO.
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
if {![string match "*P2-GATE14-C1-UART-RX-COMMAND-01*" $bag]} {
  puts stderr "REFUSE: tcl not in P2-GATE14-C1-UART-RX-COMMAND-01 bag bag=$bag"
  exit 3
}

set outdir $bag
set build_dir [file join $root build p2_gate14_c1_uart_rx_command_01]
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

set out_bit [file join $outdir arty_a7_ng_native_v1_grok_orch_p2_gate14_c1_uart_rx_command_01.bit]
set dcp_path [file join $outdir e2r_post_route.dcp]
set timing_rpt [file join $outdir report_timing_summary.rpt]
set util_rpt [file join $outdir report_utilization_route.rpt]
set cdc_rpt [file join $outdir report_cdc.rpt]
set cdc_cls [file join $outdir CDC_CLASSIFY.txt]
set route_rpt [file join $outdir report_route_status.rpt]
puts "EXEC: exclusive grok-orch P2-GATE14-C1-UART-RX-COMMAND-01 bag TCL PHYS=4 LABEL=MINHEAP PROGRAM=NO"
puts "BIT_PATH=$out_bit"

foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e arty_a7_lm06 longboot 9DC0F8DF 15B0E502} {
  if {[string match *$forbidden* [string tolower [file tail $out_bit]]]} {
    puts stderr "REFUSE: bit path collides with frozen/leftover artifact"
    exit 3
  }
}

set cdc_sv [file nativename [file join $root rtl board a7ng_wdma_cdc.sv]]
set rel_sv [file nativename [file join $root rtl board a7ng_wdma_rel_sync.sv]]
set top_sv [file nativename [file join $root rtl board arty_a7_ng_native_v1_ab_soc_top.sv]]
set tile_sv [file nativename [file join $root rtl lm weight_tile803k.sv]]
set dma_sv [file nativename [file join $root rtl ddr ddr_tile_dma.sv]]
set core_sv [file nativename [file join $root rtl lm tiny_gpt803k_core.sv]]
set bind_sv [file nativename [file join $root rtl native_graph lm a7ng_native_ctx_bind.sv]]
set cue_sv [file nativename [file join $root rtl native_graph memory a7ng_cue_soa_mig_top.sv]]
set heap_sv [file nativename [file join $root rtl native_graph topk a7ng_topk_wavefront_minheap.sv]]
set wf_sv [file nativename [file join $root rtl native_graph memory a7ng_cue_soa_wavefront.sv]]
set boot_sv [file nativename [file join $root rtl board a7ng_ddr_soa_boot.sv]]
set cdc_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$cdc_sv' | Select-Object -ExpandProperty Hash"]]
set rel_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$rel_sv' | Select-Object -ExpandProperty Hash"]]
set top_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$top_sv' | Select-Object -ExpandProperty Hash"]]
set tile_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$tile_sv' | Select-Object -ExpandProperty Hash"]]
set dma_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$dma_sv' | Select-Object -ExpandProperty Hash"]]
set core_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$core_sv' | Select-Object -ExpandProperty Hash"]]
set bind_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$bind_sv' | Select-Object -ExpandProperty Hash"]]
set cue_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$cue_sv' | Select-Object -ExpandProperty Hash"]]
set heap_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$heap_sv' | Select-Object -ExpandProperty Hash"]]
set wf_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$wf_sv' | Select-Object -ExpandProperty Hash"]]
set boot_sha [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$boot_sv' | Select-Object -ExpandProperty Hash"]]
puts "CANDIDATE_CDC_SHA256=$cdc_sha"
puts "CANDIDATE_REL_SHA256=$rel_sha"
puts "CANDIDATE_TOP_SHA256=$top_sha"
puts "CANDIDATE_TILE_SHA256=$tile_sha"
puts "CANDIDATE_DMA_SHA256=$dma_sha"
puts "CANDIDATE_CORE_SHA256=$core_sha"
puts "CANDIDATE_BIND_SHA256=$bind_sha"
puts "CANDIDATE_CUE_SHA256=$cue_sha"
puts "CANDIDATE_HEAP_SHA256=$heap_sha"
puts "CANDIDATE_WF_SHA256=$wf_sha"
puts "CANDIDATE_BOOT_SHA256=$boot_sha"
if {$cdc_sha ne "5AF2FBDA5E9D2E0F1527BD9E89D6935CDC7722BD775DCE0870683C215A06539D"} {
  puts stderr "STOP: CDC SHA drifted $cdc_sha"
  exit 3
}
if {$rel_sha ne "56C8AE66FEE38E280024F2232519D376CE4AB82F99D5413AB8862CE19B6BBDB2"} {
  puts stderr "STOP: wdma_rel_sync SHA drifted $rel_sha"
  exit 3
}
puts "NOTE: top SHA live $top_sha"
if {$tile_sha ne "06F62A3A71E00B2A8F8B6D7277488544ABD1556B03F6FE88165E24EC6A4CB430"} {
  puts stderr "STOP: tile SHA drifted $tile_sha"
  exit 3
}
if {$dma_sha ne "20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5"} {
  puts stderr "STOP: dma SHA drifted $dma_sha"
  exit 3
}
if {$core_sha ne "75706E2C804C4044CF7A76638978A617A83DE0D4E7D5A37EF703C974E8EFB5FB"} {
  puts stderr "STOP: core SHA drifted (want LN-FIX 75706E2C) $core_sha"
  exit 3
}
if {$bind_sha ne "C5F57AD1F0A81BB998234BC885EACA5EC7A4F19279E1EDBFDC5DADE163FC94CC"} {
  puts stderr "STOP: bind SHA drifted $bind_sha"
  exit 3
}
puts "NOTE: soc_top SHA live $top_sha (Gate14 C1 UART RX command path; parent 48276D2B not reused)"
if {$cue_sha ne "1721C298400EFEA7D705E507E5288ABC8BFDECB85BE0393D96DAFCC71E99A7D4"} {
  puts stderr "STOP: R5 cue/mig_top SHA drifted $cue_sha"
  exit 3
}
if {$heap_sha ne "6A6513068936295023878C7E75A1D49A6DA790BD448209B87BEE7806AA2D44E7"} {
  puts stderr "STOP: minheap SHA drifted (want ord[] 6A651306) $heap_sha"
  exit 3
}
if {$wf_sha ne "2F8888AD44AC7F4CC9B44DFE19C999392FADE396141BBFE9FB97D8F94056E06A"} {
  puts stderr "STOP: AOS wavefront SHA drifted $wf_sha"
  exit 3
}
if {$boot_sha ne "C02C8D9E190BBBCEDE86A359B6FE697C80BAF2CA1359232100F12FE70C7B52EF"} {
  puts stderr "STOP: AOS boot SHA drifted $boot_sha"
  exit 3
}

set ip_xci [file join $root vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
if {![file exists $ip_xci]} {
  puts stderr "ERROR: MIG IP missing"
  exit 2
}

create_project p2_gate14_c1_uart_rx_command_01 $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property verilog_define {SYNTHESIS A7LM06_SNAP_LUTRAM_BIND} [current_fileset]

read_ip $ip_xci
set mig_ip [get_files $ip_xci]
set_property generate_synth_checkpoint false $mig_ip
generate_target all $mig_ip
# XCI owns MIG sources (global synth). Do not glob-add generated .v.

set srcs [list \
  [file join $root rtl/board/sync_bits.sv] \
  [file join $root rtl/board/uart_tx.sv] \
  [file join $root rtl/board/a7ng_uart_rx100.sv] \
  [file join $root rtl/native_graph/control/a7ng_byte_cdc.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_uart_cmd_rx.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cmd_map.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cframe_tx.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cframe_sched.sv] \
  [file join $root rtl/board/clk_core_12p5.sv] \
  [file join $root rtl/board/a7ng_axi_read_cdc.sv] \
  [file join $root rtl/board/a7ng_wdma_cdc.sv] \
  [file join $root rtl/board/a7ng_wdma_rel_sync.sv] \
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
  [file join $root rtl/native_graph/scorer/a7ng_termgen_lane_fold6.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_array_fold6.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_wavefront_global.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv] \
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
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_gen_fast.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_teacher_off_glue.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_g1g5_cofit.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv] \
  [file join $root rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv]]

foreach s $srcs {
  if {[string match "*qstar*" [string tolower $s]]} {
    puts stderr "REFUSE: qstar source in existence SoC $s"
    exit 3
  }
  if {[string match "*serial*" [string tolower $s]]} {
    puts stderr "REFUSE: serial Top-K source in MINHEAP bag $s"
    exit 3
  }
}

add_files -norecurse $srcs
set_property include_dirs [list [file join $root rtl/native_graph/control]] [current_fileset]
add_files -fileset constrs_1 -norecurse [list \
  [file join $root constraints arty_a7_100.xdc] \
  [file join $root constraints a7ng03_cdc.xdc] \
  [file join $root constraints e2r_core_clk.xdc] \
  [file join $root constraints arty_a7_qspi.xdc] \
  $mig_xdc]

set_property top arty_a7_ng_native_v1_ab_soc_top [current_fileset]
set_property generic {SIM_FULL=0} [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "=== SYNTH P2-GATE14-C1-UART-RX-COMMAND-01 ==="
synth_design -top arty_a7_ng_native_v1_ab_soc_top -part xc7a100tcsg324-1 -generic SIM_FULL=0 -generic PHYS=4 -flatten_hierarchy rebuilt
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

puts "=== IMPLEMENT P2-GATE14-C1-UART-RX-COMMAND-01 ==="
source [file join $root vivado tcl e2r_core_clk_constraints.tcl]
e2r_apply_core_clk_constraints
if {[catch {opt_design -control_set_merge -sweep -propconst} oerr]} {
  puts stderr "GATE_FAIL opt_design $oerr"
  exit 4
}
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
set cdc_det [file join $outdir report_cdc_details_post.rpt]
report_cdc -details -file $cdc_det
report_route_status -file $route_rpt
report_control_sets -verbose -file [file join $outdir report_control_sets.rpt]
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
  puts $cf "P2-GATE14-C1-UART-RX-COMMAND-01 CDC classify (each Unsafe>0 row)"
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

set used_sl NA
set tot_sl 15850
if {[file exists $util_rpt]} {
  set uf [open $util_rpt r]
  set utxt [read $uf]
  close $uf
  if {[regexp {\|\s+Slice\s+\|\s+(\d+)\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+(\d+)} $utxt -> used_sl tot_sl]} {
    puts "SLICE_PARSE used=$used_sl tot=$tot_sl"
  } elseif {[regexp {Occupied Slices\s+\|\s+(\d+)\s+\|\s+(\d+)} $utxt -> used_sl tot_sl]} {
    puts "SLICE_PARSE occupied=$used_sl tot=$tot_sl"
  }
}
set free_sl NA
if {$used_sl ne "NA"} {
  set free_sl [expr {$tot_sl - $used_sl}]
}
set rte_err 0
if {[file exists $route_rpt]} {
  set rf [open $route_rpt r]
  set rtxt [read $rf]
  close $rf
  if {[regexp {nets with routing errors[:\s]+(\d+)} $rtxt -> rte_err]} {
    puts "ROUTE_ERR nets=$rte_err"
  }
}

set gate_pass 1
set risk_free 0
if {$n36 > 135} { puts stderr "GATE_FAIL BRAM36=$n36"; set gate_pass 0 }
if {$dsps > 240} { puts stderr "GATE_FAIL DSP=$dsps"; set gate_pass 0 }
if {$rte_err != 0} { puts stderr "GATE_FAIL route_errors=$rte_err"; set gate_pass 0 }
set persist_crit 0
if {[file exists $cdc_det]} {
  set df [open $cdc_det r]
  set dtxt [read $df]
  close $df
  foreach line [split $dtxt "\n"] {
    if {![string match "*Critical*" $line]} { continue }
    if {[string match "*persist*" [string tolower $line]]} {
      incr persist_crit
      puts "PERSIST_CDC_CRITICAL $line"
    }
  }
}
puts "PERSIST_CDC_CRITICAL_COUNT=$persist_crit"
if {$persist_crit != 0} {
  puts stderr "GATE_FAIL persist CDC Critical=$persist_crit"
  set gate_pass 0
}
if {$cdc_cand != 0} {
  puts stderr "GATE_FAIL candidate_logic_cdc=$cdc_cand (must be 0 except clock-gen documented)"
  set gate_pass 0
}
if {$free_sl ne "NA" && $free_sl < 64} { puts stderr "GATE_FAIL free_slices=$free_sl"; set gate_pass 0 }
if {$free_sl ne "NA" && $free_sl < 256} { puts "RISK free_slices=$free_sl (<256)"; set risk_free 1 }
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
if {$whs != "NA" && $whs < 0} { puts stderr "GATE_FAIL WHS=$whs"; set gate_pass 0 }
if {$ths != "NA" && $ths != 0} { puts stderr "GATE_FAIL THS=$ths"; set gate_pass 0 }
if {$core_wns != "NA" && $core_wns < 0} { puts stderr "GATE_FAIL core WNS=$core_wns"; set gate_pass 0 }
if {$ui_wns != "NA" && $ui_wns < 0} { puts stderr "GATE_FAIL ui WNS=$ui_wns"; set gate_pass 0 }

set mf [open [file join $outdir e2r_metrics.txt] w]
puts $mf "GATE=P2-GATE14-C1-UART-RX-COMMAND-01 LABEL=MINHEAP"
puts $mf "ramb36=$n36 ramb18=$n18 dsps=$dsps"
puts $mf "WNS=$wns TNS=$tns WHS=$whs THS=$ths"
puts $mf "core_WNS=$core_wns core_TNS=$core_tns ui_WNS=$ui_wns ui_TNS=$ui_tns"
puts $mf "cdc_cand=$cdc_cand persist_crit=$persist_crit gate_pass=$gate_pass risk_free=$risk_free"
puts $mf "slice_used=$used_sl slice_tot=$tot_sl free=$free_sl route_err=$rte_err"
puts $mf "CDC=$cdc_sha"
puts $mf "REL=$rel_sha"
puts $mf "TOP=$top_sha"
puts $mf "CORE=$core_sha"
puts $mf "BIND=$bind_sha"
puts $mf "TILE=$tile_sha"
puts $mf "H2=poison_i=0 UART_TOPK_PACK_POISON"
close $mf

puts "P2_GATE14_C1_METRICS ramb36=$n36 dsp=$dsps WNS=$wns TNS=$tns WHS=$whs THS=$ths free=$free_sl route_err=$rte_err cdc_cand=$cdc_cand persist_crit=$persist_crit gate_pass=$gate_pass risk_free=$risk_free"

if {$gate_pass} {
  puts "=== WRITE_BITSTREAM P2-GATE14-C1-UART-RX-COMMAND-01 ==="
  if {[catch {set_property SEVERITY {Warning} [get_drc_checks NSTD-1]} w1]} { puts "WARN nstd $w1" }
  if {[catch {set_property SEVERITY {Warning} [get_drc_checks UCIO-1]} w2]} { puts "WARN ucio $w2" }
  write_bitstream -force $out_bit
  set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
  set bf [open [file join $outdir BIT_SHA256.txt] w]
  puts $bf $bit_sha
  close $bf
  if {[string equal -nocase $bit_sha "6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A"]} {
    puts stderr "STOP: must not reuse parent existence bit 6975AB75"
    exit 3
  }
  puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO PROTOCOL_VER=0x01"
} else {
  puts "SKIP_BITSTREAM gate_pass=0 PROGRAM=NO"
  exit 5
}
puts "P2_GATE14_C1_UART_RX_COMMAND_01_IMPL_DONE LABEL=MINHEAP PHYS=4 PROGRAM=NO"
exit 0

