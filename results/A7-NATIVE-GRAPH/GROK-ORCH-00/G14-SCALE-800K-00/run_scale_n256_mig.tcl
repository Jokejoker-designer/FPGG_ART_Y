# G14-METRIC-MEASURE-01 P4 MIG_XSIM of SoC u_soa (cue_soa_mig_top PHYS=4).
# Reuses sealed tb_a7ng_ddr_cue_soa + bind probe. NO RTL EDIT. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xsimdir [file join $root tests xsim]
set outdir  $bag
set migroot [file join $root vivado ip mig_7series_0 mig_7series_0]
file mkdir $outdir
cd $xsimdir
if {[file exists xsim.dir]} { catch {file delete -force xsim.dir} }

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]

set prj [file join $outdir scale_n256.prj]
set fh [open $prj w]
puts $fh "# G14-SCALE-800K-00 N=256 MIG PHYS=4"
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/scorer/a7ng_scorer_lane.sv
  rtl/native_graph/scorer/a7ng_scorer_array.sv
  rtl/native_graph/scorer/a7ng_termgen_lane.sv
  rtl/native_graph/scorer/a7ng_termgen_lane_fold6.sv
  rtl/native_graph/scorer/a7ng_termgen_array.sv
  rtl/native_graph/scorer/a7ng_termgen_array_fold6.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_stream_minheap.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv
  rtl/native_graph/topk/a7ng_ng02_core.sv
  rtl/native_graph/frontier/a7ng_frontier_buckets.sv
  rtl/native_graph/memory/a7ng_ddr_soa_axi_bridge.sv
  rtl/native_graph/memory/a7ng_soa_plane_engine.sv
  rtl/native_graph/memory/a7ng_soa_plane_fetch.sv
  rtl/native_graph/memory/a7ng_axi_read_stream.sv
  rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv
  rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv
  rtl/ddr/mig_native_wrap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $bag tb_g14_scale_n256_mig.sv]\""
puts $fh "sv work \"[file join $bag g14_scale_hier_probe.sv]\""
foreach f [lsort [glob -nocomplain [file join $migroot user_design rtl *.v]]] {
  set bn [file tail $f]
  if {$bn eq "mig_7series_0_mig.v" || $bn eq "mig_7series_0_mig_sim.v"} { continue }
  puts $fh "verilog work \"$f\""
}
foreach d {axi clocking controller ecc ip_top phy ui} {
  foreach f [lsort [glob -nocomplain [file join $migroot user_design rtl $d *.v]]] {
    puts $fh "verilog work \"$f\""
  }
}
puts $fh "verilog work \"[file join $migroot user_design rtl mig_7series_0_mig_sim.v]\""
puts $fh "verilog work \"[file join $migroot example_design sim wiredly.v]\""
puts $fh "sv work \"[file join $migroot example_design sim ddr3_model.sv]\" -d x2Gb -d sg15E -d x16"
puts $fh "verilog work \"C:/2026.1/Vivado/data/verilog/src/glbl.v\""
close $fh

set incdir [file join $migroot example_design sim]
set xvlog_log [file join $outdir n256_xvlog.log]
if {[catch {exec $xvlog_bin -prj $prj -i $incdir > $xvlog_log 2>@1} vlog_rc]} {
  puts [read [open $xvlog_log r]]
  puts SCALE256_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $outdir n256_xelab.log]
if {[catch {exec $xelab_bin -mt off -O0 tb_g14_scale_n256_mig glbl -s g14s256 \
    -L unisims_ver -L unimacro_ver -L secureip -timescale 1ps/1ps > $xelab_log 2>@1} elab_rc]} {
  puts [read [open $xelab_log r]]
  puts SCALE256_XELAB_FAIL
  exit 3
}
set xsim_log [file join $outdir n256_xsim.log]
if {[catch {exec $xsim_bin g14s256 -R -log $xsim_log} xsim_rc]} {
  puts "xsim_rc=$xsim_rc"
}
puts [read [open $xsim_log r]]
if {[string match *SCALE_HIER* [read [open $xsim_log r]]]} {
  puts SCALE256_MIG_OK
  exit 0
}
puts SCALE256_MIG_FAIL
exit 5
