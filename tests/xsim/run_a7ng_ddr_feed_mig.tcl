# run_a7ng_ddr_feed_mig.tcl — Digilent AXI MIG + ddr_feed mig_h_rival
# Official mig.prj unmodified; compile mig_sim instead of synth mig.
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH MIG-RIVAL]
set migroot [file join $root vivado ip mig_7series_0 mig_7series_0]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}

set prj [file join $outdir mig_feed_xsim.prj]
set fh [open $prj w]
puts $fh "# mig_h_rival — Digilent AXI MIG sim; do not hand-edit mig.prj"

# Graph / feed RTL
foreach f {
  rtl/native_graph/pkg/a7ng_pkg.sv
  rtl/native_graph/memory/a7ng_mem_schema_v1.sv
  rtl/native_graph/memory/a7ng_ddr_feed_pp.sv
  rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv
  rtl/native_graph/memory/a7ng_ddr_feed_mig_top.sv
  rtl/ddr/mig_native_wrap.sv
} {
  puts $fh "sv work \"[file join $root $f]\""
}
puts $fh "sv work \"[file join $xsimdir tb_a7ng_ddr_feed_mig.sv]\""

# MIG user_design RTL except synth mig AND mig_sim (add sim once below)
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
# sim model (same module name as mig_7series_0_mig)
puts $fh "verilog work \"[file join $migroot user_design rtl mig_7series_0_mig_sim.v]\""
puts $fh "verilog work \"[file join $migroot example_design sim wiredly.v]\""
puts $fh "sv work \"[file join $migroot example_design sim ddr3_model.sv]\" -d x2Gb -d sg15E -d x16"
puts $fh "verilog work \"C:/2026.1/Vivado/data/verilog/src/glbl.v\""
close $fh
puts "WROTE $prj"

set incdir [file join $migroot example_design sim]
if {[catch {exec $xvlog_bin -prj $prj -i $incdir} vlog_out]} {
  puts $vlog_out
  puts XVLOG_FAIL
  exit 2
}
puts $vlog_out

# Vivado 2026.1: default xelab ACCESS_VIOLATION after static elab; -O0 is required (see xelab_repair_O0.log).
if {[catch {exec $xelab_bin -mt off -O0 tb_a7ng_ddr_feed_mig glbl -s tb_a7ng_ddr_feed_mig \
    -L unisims_ver -L unimacro_ver -L secureip -timescale 1ps/1ps} elab_out]} {
  puts $elab_out
  puts XELAB_FAIL
  exit 3
}
puts $elab_out

set log [file join $outdir xsim_mig_rival.log]
if {[catch {exec $xsim_bin tb_a7ng_ddr_feed_mig -runall > $log 2>@1} sim_rc]} {
  # xsim may non-zero on $finish depending on version; still parse log
  puts "xsim_rc=$sim_rc"
}
set fp [open $log r]
set sim_out [read $fp]
close $fp
puts $sim_out

if {[string match "*A7NG_MIG_RIVAL_XSIM_PASS*" $sim_out]} {
  puts A7NG_MIG_RIVAL_XSIM_OK
  exit 0
}
if {[string match "*A7NG_MIG_RIVAL_WAITING*" $sim_out]} {
  puts A7NG_MIG_RIVAL_WAITING_OK
  exit 6
}
puts A7NG_MIG_RIVAL_NO_PASS
exit 5
