set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set u3q  [file normalize [file join $bag ../U3Q-R3-STRUCTURED-QUERY-FEATURE-00]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set pkg  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set qse  [file join $root rtl/native_graph/query/a7ng_query_struct_extract.sv]
set tc   [file join $root rtl/native_graph/memory/a7ng_typeclass_scan.sv]
set mat  [file join $root rtl/native_graph/memory/a7ng_typeclass_materialize.sv]
set sc   [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv]
set hp   [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv]
set u6   [file join $root rtl/native_graph/integrate/a7ng_u6_typeclass_retrieval.sv]
set key  [file join $root rtl/native_graph/learn/a7ng_learn_key_class_context_v1.sv]
set g1   [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv]
set g2   [file join $root rtl/native_graph/learn/a7ng_context_delta.sv]
set st   [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv]
set r3b  [file join $root rtl/native_graph/integrate/a7ng_u7a_r3b_typeclass_to_learn.sv]
set tb   [file join $bag tb_u7a_r3b.sv]
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set incm [file join $root rtl/native_graph/memory]
set xvlog_log [file join $bag xvlog.log]
set srcs [list $pkg $qse $tc $mat $sc $hp $u6 $key $g1 $g2 $st $r3b $tb]
if {[catch {exec $xvlog_bin -sv {*}$srcs -i $incq -i $incc -i $incm -i $u3q -i $bag > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U7A_R3B_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin tb_u7a_r3b -s u7ar3b -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U7A_R3B_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u7ar3b -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U7A_R3B_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U7A_R3B_TYPECLASS_TO_LEARN_REACHABILITY_PASS* $body]} {
  puts U7A_R3B_NOT_PASS
  exit 5
}
puts U7A_R3B_XSIM_OK
exit 0
