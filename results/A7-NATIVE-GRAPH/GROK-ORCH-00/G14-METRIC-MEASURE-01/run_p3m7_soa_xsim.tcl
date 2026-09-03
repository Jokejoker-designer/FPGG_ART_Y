# G14-METRIC-MEASURE-01 P3/M7 SOA XSim. NO RTL EDIT. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory/a7ng_mem_schema_v1.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_array.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_lane.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_lane_fold6.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_array.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_termgen_array_fold6.sv] \
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
  [file join $root tests/xsim/a7ng_axi_soa_mem_stub.sv] \
  [file join $bag tb_g14_metric_p3m7_soa_xsim.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag p3m7_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag p3m7_xvlog.log] r]]
  puts P3M7_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_g14_metric_p3m7_soa_xsim -s g14m01soa -timescale 1ns/1ps > [file join $bag p3m7_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag p3m7_xelab.log] r]]
  puts P3M7_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim g14m01soa -runall > [file join $bag p3m7_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag p3m7_xsim.log] r]]
}
set out [read [open [file join $bag p3m7_xsim.log] r]]
puts $out
if {[string match "*G14_METRIC_P3M7_SOA_XSIM_PASS*" $out] ||
    [string match "*G14_METRIC_P3M7_SOA_XSIM_PARTIAL*" $out]} {
  puts P3M7_SOA_XSIM_OK
  exit 0
}
puts P3M7_XSIM_FAIL
exit 5
puts P3M7_SOA_XSIM_OK
exit 0
