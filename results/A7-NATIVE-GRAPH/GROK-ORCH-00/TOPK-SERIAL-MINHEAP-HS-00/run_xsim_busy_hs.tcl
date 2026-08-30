# Serial/min-heap busy handshake. PROGRAM=NO. No board. No impl.
set root [file normalize [file join [file dirname [info script]] ../../../..]]
set bag  [file normalize [file dirname [info script]]]
set xsimdir [file join $root tests xsim]
file mkdir $bag
cd $xsimdir
set xvlog_bin {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab_bin {C:/2026.1/Vivado/bin/xelab.bat}
set xsim_bin  {C:/2026.1/Vivado/bin/xsim.bat}
set prj [file join $bag minheap_busy_hs.prj]
set fh [open $prj w]
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_topk_minheap_busy_hs.sv]\""
close $fh
if {[catch {exec $xvlog_bin -sv -prj $prj > [file join $bag xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag xvlog.log] r]]
  puts XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab_bin tb_a7ng_topk_minheap_busy_hs -s minheap_busy_hs_sim -timescale 1ns/1ps > [file join $bag xelab.log] 2>@1}]} {
  puts [read [open [file join $bag xelab.log] r]]
  puts XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim_bin minheap_busy_hs_sim -runall > [file join $bag xsim.log] 2>@1}]} {
  puts [read [open [file join $bag xsim.log] r]]
}
set out [read [open [file join $bag xsim.log] r]]
puts $out
if {![string match "*TOPK_MINHEAP_BUSY_HS_XSIM_PASS*" $out]} {
  puts XSIM_FAIL
  exit 5
}

# Compile/elab product-adjacent ddr_wavefront_top with min-heap (no MIG).
set prj2 [file join $bag ddr_wavefront_minheap_elab.prj]
set fh2 [open $prj2 w]
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/scorer/a7ng_scorer_lane.sv
  rtl/native_graph/scorer/a7ng_scorer_array.sv
  rtl/native_graph/scorer/a7ng_termgen_lane.sv
  rtl/native_graph/scorer/a7ng_termgen_array.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv
  rtl/native_graph/memory/a7ng_ddr_feed_pp.sv
  rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv
  rtl/native_graph/memory/a7ng_cue_wave_stage.sv
  rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv
} {
  puts $fh2 "sv work \"[file join $root $f]\""
}
close $fh2
if {[catch {exec $xvlog_bin -sv -prj $prj2 > [file join $bag xvlog_wf.log] 2>@1}]} {
  puts [read [open [file join $bag xvlog_wf.log] r]]
  puts WF_XVLOG_FAIL
  exit 6
}
if {[catch {exec $xelab_bin a7ng_ddr_wavefront_top -s ddr_wavefront_minheap_elab -timescale 1ns/1ps > [file join $bag xelab_wf.log] 2>@1}]} {
  puts [read [open [file join $bag xelab_wf.log] r]]
  puts WF_XELAB_FAIL
  exit 7
}
puts "DDR_WAVEFRONT_MINHEAP_XELAB_OK"
exit 0
