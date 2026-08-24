set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH NATIVE-V1-AB-INTEGRATE-ACCEPT-00]
set migroot [file join $root vivado ip mig_7series_0 mig_7series_0]
file mkdir $outdir
cd $xsimdir
if {[file exists xsim.dir]} { catch {file delete -force xsim.dir} }
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set prj [file join $outdir native_v1_ab_mig_xsim.prj]
set fh [open $prj w]
puts $fh "# native_v1_ab_integrate_accept_00 MIG_XSIM"
foreach f {
  rtl/lm/a7lm06_pkg.sv
  rtl/lm/isqrt32.sv
  rtl/lm/floordiv_s48.sv
  rtl/lm/weight_bram803k.sv
  rtl/lm/weight_bram_tdp8.sv
  rtl/lm/weight_tile803k.sv
  rtl/lm/act_ram128k16.sv
  rtl/lm/snap_ram4k16.sv
  rtl/lm/tiny_gpt803k_core.sv
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/scorer/a7ng_scorer_lane.sv
  rtl/native_graph/scorer/a7ng_scorer_array.sv
  rtl/native_graph/scorer/a7ng_termgen_lane.sv
  rtl/native_graph/scorer/a7ng_termgen_array.sv
  rtl/native_graph/topk/a7ng_topk.sv
  rtl/native_graph/topk/a7ng_topk_wavefront_global.sv
  rtl/native_graph/topk/a7ng_ng02_core.sv
  rtl/native_graph/frontier/a7ng_frontier_buckets.sv
  rtl/native_graph/memory/a7ng_ddr_soa_axi_bridge.sv
  rtl/native_graph/memory/a7ng_soa_plane_engine.sv
  rtl/native_graph/memory/a7ng_soa_plane_fetch.sv
  rtl/native_graph/memory/a7ng_axi_read_stream.sv
  rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv
  rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv
  rtl/native_graph/integrate/a7ng_lm_graph_arb.sv
  rtl/native_graph/lm/a7ng_native_ctx_bind.sv
  rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv
  rtl/ddr/mig_native_wrap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_native_v1_ab_mig.sv]\""
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
set xvlog_log [file join $outdir xvlog_ab_mig.log]
if {[catch {exec $xvlog_bin -prj $prj -i $incdir > $xvlog_log 2>@1} vlog_rc]} {
  puts [read [open $xvlog_log r]]
  puts XVLOG_FAIL
  exit 2
}
puts [read [open $xvlog_log r]]
set xelab_log [file join $outdir xelab_ab_mig.log]
if {[catch {exec $xelab_bin -mt off -O0 tb_a7ng_native_v1_ab_mig glbl -s tb_a7ng_native_v1_ab_mig_sim \
    -L unisims_ver -L unimacro_ver -L secureip -timescale 1ps/1ps > $xelab_log 2>@1} elab_rc]} {
  puts [read [open $xelab_log r]]
  puts XELAB_FAIL
  exit 3
}
puts [read [open $xelab_log r]]
set log [file join $outdir xsim_ab_mig.log]
if {[catch {exec $xsim_bin tb_a7ng_native_v1_ab_mig_sim -runall > $log 2>@1} sim_rc]} {
  puts "xsim_rc=$sim_rc"
}
set sim_out [read [open $log r]]
puts $sim_out
if {[string match "*NATIVE_V1_AB_MIG_XSIM_PASS*" $sim_out]} {
  puts NATIVE_V1_AB_MIG_XSIM_OK
  exit 0
}
puts NATIVE_V1_AB_MIG_XSIM_NO_PASS
exit 5
