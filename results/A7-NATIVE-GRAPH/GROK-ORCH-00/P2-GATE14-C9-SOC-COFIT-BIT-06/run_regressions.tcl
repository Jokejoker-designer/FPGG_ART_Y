# P2-GATE14-C9-SOC-COFIT-BIT-06 parent regressions. PROGRAM=NO.
# G1 G2 G3 G4 + stream minheap + C9-03 graph. No board. No 40-fact board.
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
  set siml [file join $bag regr_${name}_xsim.log]
  puts "=== REGR $name ==="
  if {[catch {exec $xvlog -sv {*}$srcs > $vlog 2>@1}]} {
    puts [read [open $vlog r]]; puts "REGR_XVLOG_FAIL $name"; set fail 1; return
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > $elab 2>@1}]} {
    puts [read [open $elab r]]; puts "REGR_XELAB_FAIL $name"; set fail 1; return
  }
  if {[catch {exec $xsim $snap -runall > $siml 2>@1}]} {
    puts [read [open $siml r]]
  }
  set out [read [open $siml r]]
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
set hp  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv]
set st  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv]
set gr  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv]

sim g1 [list $g1 [file join [pwd] tb_a7ng_feedback_resolver.sv]] \
  tb_a7ng_feedback_resolver c9soc06_g1 FEEDBACK_RESOLVER_UNIT_XSIM_PASS

sim g2 [list $g2 [file join [pwd] tb_a7ng_context_delta.sv]] \
  tb_a7ng_context_delta c9soc06_g2 CONTEXT_DELTA_UNIT_XSIM_PASS

sim g3 [list $ngp $sc $g1 $g2 $g3 [file join [pwd] tb_a7ng_causal_learn_fast.sv]] \
  tb_a7ng_causal_learn_fast c9soc06_g3 CAUSAL_LEARN_FAST_XSIM_PASS

sim g4 [list $ngp $sc $g1 $g2 $g4 [file join [pwd] tb_a7ng_persist_gen_fast.sv]] \
  tb_a7ng_persist_gen_fast c9soc06_g4 PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS

sim minheap [list $ngp $hp [file join [pwd] tb_a7ng_topk_stream_minheap_diff.sv]] \
  tb_a7ng_topk_stream_minheap_diff c9soc06_hp LOCAL_MINHEAP_STREAM_TOP8_XSIM_PASS

sim c9graph [list $ngp $sc $g1 $g2 $st $hp $gr \
  [file join $root results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03/tb_a7ng_learned_prior_graph.sv]] \
  tb_a7ng_learned_prior_graph c9soc06_c9g C9_LEARNED_PRIOR_GRAPH_XSIM_PASS

if {$fail} {
  puts C9SOC06_REGRESSION_FAIL
  exit 5
}
puts C9SOC06_REGRESSION_PASS
exit 0
