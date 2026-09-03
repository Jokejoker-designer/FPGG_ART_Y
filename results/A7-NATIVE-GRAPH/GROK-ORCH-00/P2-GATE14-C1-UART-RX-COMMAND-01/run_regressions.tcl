# P2-GATE14-C1-UART-RX-COMMAND-01 parent regressions. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set fail 0

proc sim {name srcs top snap pass} {
  global bag xvlog xelab xsim fail
  set vlog [file join $bag regr_${name}_xvlog.log]
  set elab [file join $bag regr_${name}_xelab.log]
  set sim  [file join $bag regr_${name}_xsim.log]
  puts "=== REGR $name ==="
  if {[catch {exec $xvlog -sv {*}$srcs > $vlog 2>@1}]} {
    puts [read [open $vlog r]]; puts "REGR_XVLOG_FAIL $name"; set fail 1; return
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > $elab 2>@1}]} {
    puts [read [open $elab r]]; puts "REGR_XELAB_FAIL $name"; set fail 1; return
  }
  if {[catch {exec $xsim $snap -runall > $sim 2>@1}]} {
    puts [read [open $sim r]]
  }
  set out [read [open $sim r]]
  puts $out
  if {![string match "*${pass}*" $out]} {
    puts "REGR_XSIM_FAIL $name"; set fail 1
  } else {
    puts "REGR_OK $name"
  }
}

set ngp [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set g1  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv]
set g2  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv]
set g3  [file join $root rtl/native_graph/learn/a7ng_causal_learn_fast.sv]
set g4  [file join $root rtl/native_graph/learn/a7ng_persist_gen_fast.sv]
set sc  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv]
set lm  [list \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv]]

sim g1 [list $g1 [file join [pwd] tb_a7ng_feedback_resolver.sv]] \
  tb_a7ng_feedback_resolver cofit_g1 FEEDBACK_RESOLVER_UNIT_XSIM_PASS

sim g2 [list $g2 [file join [pwd] tb_a7ng_context_delta.sv]] \
  tb_a7ng_context_delta cofit_g2 CONTEXT_DELTA_UNIT_XSIM_PASS

sim g3 [list $ngp $sc $g1 $g2 $g3 [file join [pwd] tb_a7ng_causal_learn_fast.sv]] \
  tb_a7ng_causal_learn_fast cofit_g3 CAUSAL_LEARN_FAST_XSIM_PASS

sim g4 [list $ngp $sc $g1 $g2 $g4 [file join [pwd] tb_a7ng_persist_gen_fast.sv]] \
  tb_a7ng_persist_gen_fast cofit_g4 PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS

sim afast [concat $lm [list [file join [pwd] tb_a7lm06_afast_lnfix_regression.sv]]] \
  tb_a7lm06_afast_lnfix_regression cofit_afast "LN_FIX_AFAST_REGRESSION_PASS arm=NEW"

set g5src [concat [list $ngp $sc $g1 $g2 $g4 \
  [file join $root rtl/native_graph/lm/a7ng_native_ctx_bind.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_teacher_off_glue.sv]] $lm [list \
  [file join $root rtl/native_graph/integrate/a7ng_teacher_off_soc_xsim.sv] \
  [file join [pwd] tb_a7ng_teacher_off_soc_xsim_r1.sv]]]
sim g5r1 $g5src tb_a7ng_teacher_off_soc_xsim_r1 cofit_g5r1 \
  "TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN"

set pax [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv]
sim axi [list $ngp $sc $g1 $g2 $g4 $pax \
  [file join [pwd] tb_a7ng_persist_axi_mem.sv] \
  [file join [pwd] tb_a7ng_persist_axi_bridge.sv]] \
  tb_a7ng_persist_axi_bridge mig_paxi PERSIST_AXI_MIG_XSIM_PASS

sim coll [list $ngp $pax \
  [file join [pwd] tb_a7ng_persist_axi_mem.sv] \
  [file join [pwd] tb_a7ng_persist_axi_collision.sv]] \
  tb_a7ng_persist_axi_collision mig_pcoll PERSIST_AXI_COLLISION_XSIM_PASS

sim cdc [list $ngp $pax \
  [file join [pwd] tb_a7ng_persist_axi_mem.sv] \
  [file join [pwd] tb_a7ng_persist_axi_cdc.sv]] \
  tb_a7ng_persist_axi_cdc mig_pcdc PERSIST_AXI_CDC_XSIM_PASS

sim wdma_rel [list \
  [file join $root rtl/board/a7ng_wdma_rel_sync.sv] \
  [file join [pwd] tb_a7ng_wdma_rel_sync.sv]] \
  tb_a7ng_wdma_rel_sync wdma_rel WDMA_REL_CDC_XSIM_PASS
if {$fail} {
  puts GATE14_C1_REGRESSION_FAIL
  exit 5
}
puts GATE14_C1_REGRESSION_PASS
exit 0
