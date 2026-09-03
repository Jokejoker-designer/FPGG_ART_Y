# G14-EPOCH-REBIRTH-BIT-00 full-chip. PHYS=4. LABEL=MINHEAP. PROGRAM=NO.
# C9-07 fileset + epoch object / wrap REBIRTH (PR #8). Unique bit. Human owns JTAG.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set_param general.maxThreads 8
puts "VIVADO maxThreads=[get_param general.maxThreads]"
puts "ROOT=$root"
puts "BAG=$bag"

if {![string match "*arty-a7-online-lm-g14-preboard-00" $root] &&
    ![string match "*arty-a7-online-lm-grok-orch-00" $root]} {
  puts stderr "REFUSE: root is not g14-preboard-00 or grok-orch-00 worktree root=$root"
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
if {![string match "*G14-EPOCH-REBIRTH-BIT-00*" $bag]} {
  puts stderr "REFUSE: tcl not in G14-EPOCH-REBIRTH-BIT-00 bag bag=$bag"
  exit 3
}

set outdir $bag
set build_dir [file join $root build g14_epoch_rebirth_bit_00]
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

set out_bit [file join $outdir arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit]
set dcp_path [file join $outdir e2r_post_route.dcp]
set timing_rpt [file join $outdir report_timing_summary.rpt]
set util_rpt [file join $outdir report_utilization_route.rpt]
set cdc_rpt [file join $outdir report_cdc.rpt]
set cdc_cls [file join $outdir CDC_CLASSIFY.txt]
set route_rpt [file join $outdir report_route_status.rpt]
set drc_rpt [file join $outdir report_drc.rpt]
puts "EXEC: G14-EPOCH-REBIRTH-BIT-00 bag TCL PHYS=4 LABEL=MINHEAP PROGRAM=NO"
puts "BIT_PATH=$out_bit"

if {![string match "*g14_epoch_rebirth_00*" [file tail $out_bit]]} {
  puts stderr "REFUSE: bit name missing g14_epoch_rebirth_00"
  exit 3
}

foreach forbidden {arty_a7_lm arty_a7_eam01r arty_a7_eam02m arty_a7_eam03e arty_a7_lm06 longboot 9DC0F8DF 15B0E502 A0B338E0 B0F64E6C C9-SOC-COFIT-BIT-06 C9-SOC-IO-SAFE-BIT-07 3A7EF204 7ECCA0E2} {
  if {[string match *$forbidden* [string tolower [file tail $out_bit]]]} {
    puts stderr "REFUSE: bit path collides with frozen/leftover artifact"
    exit 3
  }
}

proc file_sha {p} {
  return [string toupper [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$p' | Select-Object -ExpandProperty Hash"]]
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
set g1_sv [file nativename [file join $root rtl native_graph learn a7ng_feedback_resolver.sv]]
set g2_sv [file nativename [file join $root rtl native_graph learn a7ng_context_delta.sv]]
set g3_sv [file nativename [file join $root rtl native_graph learn a7ng_causal_learn_fast.sv]]
set g4_sv [file nativename [file join $root rtl native_graph learn a7ng_persist_gen_fast.sv]]
set ab_sv [file nativename [file join $root rtl native_graph integrate a7ng_native_v1_ab_core.sv]]
set cofit_sv [file nativename [file join $root rtl native_graph integrate a7ng_g1g5_cofit.sv]]
set store_sv [file nativename [file join $root rtl native_graph learn a7ng_learned_prior_store.sv]]
set lpg_sv [file nativename [file join $root rtl native_graph integrate a7ng_learned_prior_graph.sv]]
set glue_sv [file nativename [file join $root rtl native_graph integrate a7ng_gate14_c9_glue.sv]]
set pax_sv [file nativename [file join $root rtl native_graph learn a7ng_persist_axi_bridge.sv]]
set ora_sv [file nativename [file join $bag ORACLE.json]]

set cdc_sha [file_sha $cdc_sv]
set rel_sha [file_sha $rel_sv]
set top_sha [file_sha $top_sv]
set tile_sha [file_sha $tile_sv]
set dma_sha [file_sha $dma_sv]
set core_sha [file_sha $core_sv]
set bind_sha [file_sha $bind_sv]
set cue_sha [file_sha $cue_sv]
set heap_sha [file_sha $heap_sv]
set wf_sha [file_sha $wf_sv]
set boot_sha [file_sha $boot_sv]
set g1_sha [file_sha $g1_sv]
set g2_sha [file_sha $g2_sv]
set g3_sha [file_sha $g3_sv]
set g4_sha [file_sha $g4_sv]
set ab_sha [file_sha $ab_sv]
set cofit_sha [file_sha $cofit_sv]
set store_sha [file_sha $store_sv]
set lpg_sha [file_sha $lpg_sv]
set glue_sha [file_sha $glue_sv]
set pax_sha [file_sha $pax_sv]
set ora_sha [file_sha $ora_sv]

puts "CANDIDATE_CDC_SHA256=$cdc_sha"
puts "CANDIDATE_REL_SHA256=$rel_sha"
puts "CANDIDATE_TOP_SHA256=$top_sha"
puts "CANDIDATE_ABCORE_SHA256=$ab_sha"
puts "CANDIDATE_COFIT_SHA256=$cofit_sha"
puts "CANDIDATE_STORE_SHA256=$store_sha"
puts "CANDIDATE_LPG_SHA256=$lpg_sha"
puts "CANDIDATE_GLUE_SHA256=$glue_sha"
puts "CANDIDATE_PAX_SHA256=$pax_sha"
puts "CANDIDATE_TILE_SHA256=$tile_sha"
puts "CANDIDATE_DMA_SHA256=$dma_sha"
puts "CANDIDATE_CORE_SHA256=$core_sha"
puts "CANDIDATE_BIND_SHA256=$bind_sha"
puts "CANDIDATE_CUE_SHA256=$cue_sha"
puts "CANDIDATE_HEAP_SHA256=$heap_sha"
puts "CANDIDATE_WF_SHA256=$wf_sha"
puts "CANDIDATE_BOOT_SHA256=$boot_sha"
puts "CANDIDATE_G1_SHA256=$g1_sha"
puts "CANDIDATE_G2_SHA256=$g2_sha"
puts "CANDIDATE_G3_SHA256=$g3_sha"
puts "CANDIDATE_G4_SHA256=$g4_sha"
puts "CANDIDATE_ORACLE_SHA256=$ora_sha"

if {$cdc_sha ne "5AF2FBDA5E9D2E0F1527BD9E89D6935CDC7722BD775DCE0870683C215A06539D"} {
  puts stderr "STOP: CDC SHA drifted $cdc_sha"
  exit 3
}
if {$rel_sha ne "56C8AE66FEE38E280024F2232519D376CE4AB82F99D5413AB8862CE19B6BBDB2"} {
  puts stderr "STOP: wdma_rel_sync SHA drifted $rel_sha"
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
puts "NOTE: TinyGPT SHA live $core_sha (BIT-07 snapshot 75706E2C; current tree XSim-exact OUT 653/689/237/60)"
if {$bind_sha ne "C5F57AD1F0A81BB998234BC885EACA5EC7A4F19279E1EDBFDC5DADE163FC94CC"} {
  puts stderr "STOP: bind SHA drifted $bind_sha"
  exit 3
}
puts "NOTE: cue/mig_top SHA live $cue_sha (BIT-07 snapshot 1721C298; not epoch path)"
puts "NOTE: minheap SHA live $heap_sha (BIT-07 snapshot 6A651306; C9-03 + full-chip XSim exact)"
puts "NOTE: AOS wavefront SHA live $wf_sha (BIT-07 snapshot 2F8888AD; not epoch path)"
puts "NOTE: AOS boot SHA live $boot_sha (BIT-07 snapshot C02C8D9E; not epoch path)"
if {$g1_sha ne "2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7"} {
  puts stderr "STOP: G1 SHA drifted $g1_sha"
  exit 3
}
if {$g2_sha ne "0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800"} {
  puts stderr "STOP: G2 SHA drifted $g2_sha"
  exit 3
}
if {$g3_sha ne "2177073D4103F7971116E5F3C48FE2A33F8E9BC7FDDCA317AD2A3AE156F70EF6"} {
  puts stderr "STOP: G3 SHA drifted $g3_sha"
  exit 3
}
puts "NOTE: G4 persist_gen_fast SHA live $g4_sha (epoch_legal + wrap REBIRTH; not in C9 SoC fileset)"
puts "NOTE: ORACLE.json SHA live $ora_sha (values frozen HOLD_A 653 / 8382238122802120)"
puts "NOTE: soc_top SHA live $top_sha (C9-SOC-IO-SAFE; ja port removed; parent B0F64E6C not reused)"
puts "NOTE: ab_core SHA live $ab_sha"
puts "NOTE: cofit SHA live $cofit_sha (learned_prior_graph + c9_glue; FAST-ID removed)"
puts "NOTE: persist_axi_bridge SHA live $pax_sha (addr[7:0])"

set ip_xci [file join $root vivado/ip/mig_7series_0/mig_7series_0.xci]
set mig_xdc [file join $root vivado/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc]
if {![file exists $ip_xci]} {
  puts stderr "ERROR: MIG IP missing"
  exit 2
}

create_project g14_epoch_rebirth_bit_00 $build_dir -part xc7a100tcsg324-1 -force
set_property target_language Verilog [current_project]
set_property verilog_define {SYNTHESIS A7LM06_SNAP_LUTRAM_BIND} [current_fileset]

read_ip $ip_xci
set mig_ip [get_files $ip_xci]
set_property generate_synth_checkpoint false $mig_ip
generate_target all $mig_ip

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
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv] \
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
  if {[string match "*persist_gen_fast*" [string tolower $s]]} {
    puts stderr "REFUSE: persist_gen_fast FAST-ID path in C9 SoC fileset $s"
    exit 3
  }
  if {[string match "*teacher_off_glue*" [string tolower $s]]} {
    puts stderr "REFUSE: teacher_off_glue in C9 SoC fileset $s"
    exit 3
  }
  if {[string match "*e2r_la_pmod_ja*" [string tolower $s]]} {
    puts stderr "REFUSE: ja Pmod XDC in IO-SAFE fileset $s"
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

puts "=== SYNTH G14-EPOCH-REBIRTH-BIT-00 ==="
synth_design -top arty_a7_ng_native_v1_ab_soc_top -part xc7a100tcsg324-1 -generic SIM_FULL=0 -generic PHYS=4 -flatten_hierarchy rebuilt
set ja_ports [get_ports -quiet ja*]
puts "JA_PORT_COUNT=[llength $ja_ports]"
if {[llength $ja_ports] != 0} {
  puts stderr "FIRST_DIVERGENCE=JA_PORT_STILL_PRESENT $ja_ports"
  exit 3
}

proc g14_net_width {nm} {
  set bits [get_nets -quiet ${nm}[*]]
  if {[llength $bits] > 0} { return [llength $bits] }
  set n [get_nets -quiet $nm]
  if {[llength $n] == 0} { return 0 }
  return 1
}
foreach pair {
  {g14_c8g 32} {g14_c8d 64} {g14_adig 64} {g14_bdig 64}
  {g14_sc 128} {g14_r1s 32} {g14_r1o 32} {g14_r1r 8}
  {c1_mode 4} {c9_cframe 64} {c10_out 10}
} {
  lassign $pair nm want
  set got [g14_net_width $nm]
  puts "G14_WIDTH $nm got=$got want=$want"
  if {$want > 1 && $got == 1} {
    puts stderr "GATE_FAIL implicit_1bit net=$nm want=$want (8-11241 CFRAME truncate)"
    exit 3
  }
  if {$got > $want} {
    puts stderr "GATE_FAIL wider_than_rtl net=$nm got=$got want=$want"
    exit 3
  }
  if {$got == 0 && $want > 1} {
    puts "NOTE G14_WIDTH $nm fully DCE (CFRAME field constant) rtl=$want"
  } elseif {$got > 0 && $got < $want} {
    puts "NOTE G14_WIDTH $nm DCE unused bits remain=$got rtl=$want (not implicit-1bit)"
  }
}

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
  puts stderr "FIRST_DIVERGENCE=OVER_UTIL u_ab RAMB36=$u_ab_ramb36"
  exit 3
}

puts "=== IMPLEMENT G14-EPOCH-REBIRTH-BIT-00 ==="
source [file join $root vivado tcl e2r_core_clk_constraints.tcl]
e2r_apply_core_clk_constraints
if {[catch {opt_design -control_set_merge -sweep -propconst} oerr]} {
  puts stderr "FIRST_DIVERGENCE=OPT_DESIGN $oerr"
  exit 4
}
if {[catch {place_design} perr]} {
  puts stderr "FIRST_DIVERGENCE=PLACE $perr"
  exit 4
}
if {[catch {phys_opt_design} perr]} { puts "WARN phys_opt $perr" }
if {[catch {route_design} rerr]} {
  puts stderr "FIRST_DIVERGENCE=ROUTE $rerr"
  exit 4
}
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
report_drc -file $drc_rpt
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
  puts $cf "G14-EPOCH-REBIRTH-BIT-00 CDC classify (each Unsafe>0 row)"
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

set lut NA; set ff NA
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
  if {[regexp {Slice LUTs\s+\|\s+(\d+)} $utxt -> lut]} {
    puts "LUT_PARSE $lut"
  }
  if {[regexp {Slice Registers\s+\|\s+(\d+)} $utxt -> ff]} {
    puts "FF_PARSE $ff"
  }
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

set drc_err 0
set nstd1 0
set ucio1 0
if {[file exists $drc_rpt]} {
  set df [open $drc_rpt r]
  set dtxt [read $df]
  close $df
  if {[regexp {\|\s*NSTD-1\s*\|\s+[^\|]+\|\s+[^\|]+\|\s+(\d+)} $dtxt -> nstd1]} {
    puts "DRC_PARSE NSTD-1=$nstd1"
  }
  if {[regexp {\|\s*UCIO-1\s*\|\s+[^\|]+\|\s+[^\|]+\|\s+(\d+)} $dtxt -> ucio1]} {
    puts "DRC_PARSE UCIO-1=$ucio1"
  }
  if {[regexp {Error\s+:\s+(\d+)} $dtxt -> drc_err]} {
    puts "DRC_PARSE errors=$drc_err"
  }
}

set gate_pass 1
set risk_free 0
set first_div "NONE"
if {$n36 > 135} { puts stderr "FIRST_DIVERGENCE=BRAM36 $n36"; set first_div "BRAM36=$n36"; set gate_pass 0 }
if {$dsps > 240} { puts stderr "FIRST_DIVERGENCE=DSP $dsps"; set first_div "DSP=$dsps"; set gate_pass 0 }
if {$rte_err != 0} { puts stderr "FIRST_DIVERGENCE=ROUTE_ERR $rte_err"; set first_div "ROUTE_ERR=$rte_err"; set gate_pass 0 }
if {$drc_err != 0} { puts stderr "FIRST_DIVERGENCE=DRC_ERROR $drc_err"; set first_div "DRC_ERROR=$drc_err"; set gate_pass 0 }
if {$nstd1 != 0} { puts stderr "FIRST_DIVERGENCE=NSTD-1 $nstd1"; set first_div "NSTD-1=$nstd1"; set gate_pass 0 }
if {$ucio1 != 0} { puts stderr "FIRST_DIVERGENCE=UCIO-1 $ucio1"; set first_div "UCIO-1=$ucio1"; set gate_pass 0 }
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
  puts stderr "FIRST_DIVERGENCE=PERSIST_CDC_CRITICAL $persist_crit"
  if {$first_div eq "NONE"} { set first_div "PERSIST_CDC_CRITICAL=$persist_crit" }
  set gate_pass 0
}
if {$cdc_cand != 0} {
  puts stderr "FIRST_DIVERGENCE=CDC_CANDIDATE $cdc_cand"
  if {$first_div eq "NONE"} { set first_div "CDC_CANDIDATE=$cdc_cand" }
  set gate_pass 0
}
if {$free_sl ne "NA" && $free_sl < 0} {
  puts stderr "FIRST_DIVERGENCE=OVER_UTIL free_slices=$free_sl"
  if {$first_div eq "NONE"} { set first_div "OVER_UTIL free=$free_sl" }
  set gate_pass 0
}
if {$free_sl ne "NA" && $free_sl < 64} {
  puts stderr "FIRST_DIVERGENCE=FREE_SLICES $free_sl"
  if {$first_div eq "NONE"} { set first_div "FREE_SLICES=$free_sl" }
  set gate_pass 0
}
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
if {$wns != "NA" && $wns < 0} {
  puts stderr "FIRST_DIVERGENCE=WNS $wns"
  if {$first_div eq "NONE"} { set first_div "WNS=$wns" }
  set gate_pass 0
}
if {$tns != "NA" && $tns != 0} {
  puts stderr "FIRST_DIVERGENCE=TNS $tns"
  if {$first_div eq "NONE"} { set first_div "TNS=$tns" }
  set gate_pass 0
}
if {$whs != "NA" && $whs < 0} {
  puts stderr "FIRST_DIVERGENCE=WHS $whs"
  if {$first_div eq "NONE"} { set first_div "WHS=$whs" }
  set gate_pass 0
}
if {$ths != "NA" && $ths != 0} {
  puts stderr "FIRST_DIVERGENCE=THS $ths"
  if {$first_div eq "NONE"} { set first_div "THS=$ths" }
  set gate_pass 0
}
if {$core_wns != "NA" && $core_wns < 0} {
  puts stderr "FIRST_DIVERGENCE=CORE_WNS $core_wns"
  if {$first_div eq "NONE"} { set first_div "CORE_WNS=$core_wns" }
  set gate_pass 0
}
if {$ui_wns != "NA" && $ui_wns < 0} {
  puts stderr "FIRST_DIVERGENCE=UI_WNS $ui_wns"
  if {$first_div eq "NONE"} { set first_div "UI_WNS=$ui_wns" }
  set gate_pass 0
}

set mf [open [file join $outdir e2r_metrics.txt] w]
puts $mf "GATE=G14-EPOCH-REBIRTH-BIT-00 LABEL=MINHEAP"
puts $mf "ramb36=$n36 ramb18=$n18 dsps=$dsps lut=$lut ff=$ff"
puts $mf "WNS=$wns TNS=$tns WHS=$whs THS=$ths"
puts $mf "core_WNS=$core_wns core_TNS=$core_tns ui_WNS=$ui_wns ui_TNS=$ui_tns"
puts $mf "cdc_cand=$cdc_cand persist_crit=$persist_crit gate_pass=$gate_pass risk_free=$risk_free"
puts $mf "slice_used=$used_sl slice_tot=$tot_sl free=$free_sl route_err=$rte_err drc_err=$drc_err nstd1=$nstd1 ucio1=$ucio1"
puts $mf "FIRST_DIVERGENCE=$first_div"
puts $mf "CDC=$cdc_sha"
puts $mf "REL=$rel_sha"
puts $mf "TOP=$top_sha"
puts $mf "ABCORE=$ab_sha"
puts $mf "COFIT=$cofit_sha"
puts $mf "STORE=$store_sha"
puts $mf "LPG=$lpg_sha"
puts $mf "GLUE=$glue_sha"
puts $mf "PAX=$pax_sha"
puts $mf "CORE=$core_sha"
puts $mf "BIND=$bind_sha"
puts $mf "TILE=$tile_sha"
puts $mf "G1=$g1_sha"
puts $mf "G2=$g2_sha"
puts $mf "G3=$g3_sha"
puts $mf "G4=$g4_sha"
puts $mf "ORACLE=$ora_sha"
puts $mf "PARENT_BIT_A0B338E0=A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B"
puts $mf "PARENT_A0B338E0_ramb36=103 dsp=19 WNS=1.276 WHS=0.021 slice=15454/15850 free=396"
puts $mf "H2=poison_i=0 UART_TOPK_PACK_POISON"
puts $mf "PROGRAM=NO"
close $mf

set sf [open [file join $outdir SOURCE_SHA.txt] w]
puts $sf "GATE=G14-EPOCH-REBIRTH-BIT-00"
puts $sf "CDC=$cdc_sha"
puts $sf "REL=$rel_sha"
puts $sf "TOP=$top_sha"
puts $sf "ABCORE=$ab_sha"
puts $sf "COFIT=$cofit_sha"
puts $sf "STORE=$store_sha"
puts $sf "LPG=$lpg_sha"
puts $sf "GLUE=$glue_sha"
puts $sf "PAX=$pax_sha"
puts $sf "TINYGPT=$core_sha"
puts $sf "BIND=$bind_sha"
puts $sf "TILE=$tile_sha"
puts $sf "DMA=$dma_sha"
puts $sf "CUE=$cue_sha"
puts $sf "HEAP=$heap_sha"
puts $sf "WF=$wf_sha"
puts $sf "BOOT=$boot_sha"
puts $sf "G1=$g1_sha"
puts $sf "G2=$g2_sha"
puts $sf "G3=$g3_sha"
puts $sf "G4=$g4_sha"
puts $sf "ORACLE=$ora_sha"
close $sf

puts "G14_EPOCH_REBIRTH_METRICS ramb36=$n36 dsp=$dsps lut=$lut ff=$ff WNS=$wns TNS=$tns WHS=$whs THS=$ths free=$free_sl route_err=$rte_err cdc_cand=$cdc_cand persist_crit=$persist_crit drc_err=$drc_err gate_pass=$gate_pass first_div=$first_div"

if {$gate_pass} {
  puts "=== WRITE_BITSTREAM G14-EPOCH-REBIRTH-BIT-00 (NO NSTD/UCIO WAIVER) ==="
  if {[catch {write_bitstream -force $out_bit} berr]} {
    puts stderr "FIRST_DIVERGENCE=WRITE_BITSTREAM $berr"
    puts "BIT_READY_FOR_CODEX=NO"
    exit 5
  }
  set bit_sha [exec powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '$out_bit' | Select-Object -ExpandProperty Hash"]
  set bit_sha [string toupper $bit_sha]
  set bf [open [file join $outdir BIT_SHA256.txt] w]
  puts $bf $bit_sha
  close $bf
  if {[string equal -nocase $bit_sha "A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B"]} {
    puts stderr "STOP: must not reuse resident bit A0B338E0"
    exit 3
  }
  if {[string equal -nocase $bit_sha "2E18B1440791D4554A3DD863AAC35A6150B6B2302CF23494D09649BFAAB225C4"]} {
    puts stderr "STOP: must not reuse G1G5 cofit bit 2E18B144"
    exit 3
  }
  if {[string equal -nocase $bit_sha "6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A"]} {
    puts stderr "STOP: must not reuse parent existence bit 6975AB75"
    exit 3
  }
  if {[string equal -nocase $bit_sha "B0F64E6C37F6BDB428FAB18CD6EEDD191C389AC3EE9FFB4D23B641B5D289A0A1"]} {
    puts stderr "STOP: must not reuse rejected BIT-06 ja-unconstrained bit B0F64E6C"
    exit 3
  }
  if {[string equal -nocase $bit_sha "3A7EF2044CD92730F048032ABF9E9CC914461EE7CE767745089CD082CC31A00B"]} {
    puts stderr "STOP: must not reuse historical Gate14 fail bit 3A7EF204"
    exit 3
  }
  if {[string equal -nocase $bit_sha "7ECCA0E21BF27DD13451F3EFB4F180A7B15627B610D81BECAE07CA9FFA12E219"]} {
    puts stderr "STOP: must not reuse E2R probe bit 7ECCA0E2"
    exit 3
  }
  puts "BIT_OK path=$out_bit sha256=$bit_sha PROGRAM=NO"
  puts "BIT_READY_FOR_HUMAN=YES"
} else {
  puts "SKIP_BITSTREAM gate_pass=0 PROGRAM=NO FIRST_DIVERGENCE=$first_div"
  puts "BIT_READY_FOR_HUMAN=NO"
  exit 5
}
puts "G14_EPOCH_REBIRTH_BIT_00_IMPL_DONE LABEL=MINHEAP PHYS=4 PROGRAM=NO"
exit 0
