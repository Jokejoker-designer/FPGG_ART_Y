set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-EMB-RG-SWITCH-CXSIM-00]
file mkdir $outdir
cd $outdir

set src [list \
  [file join $root rtl/lm a7lm06_pkg.sv] \
  [file join $root rtl/lm isqrt32.sv] \
  [file join $root rtl/lm floordiv_s48.sv] \
  [file join $root rtl/lm weight_bram803k.sv] \
  [file join $root rtl/lm weight_bram_tdp8.sv] \
  [file join $root rtl/lm weight_tile803k.sv] \
  [file join $root rtl/lm act_ram128k16.sv] \
  [file join $root rtl/lm snap_ram4k16.sv] \
  [file join $root rtl/lm tiny_gpt803k_core.sv] \
  [file join $xsimdir tb_e2r_emb_rg_switch_cxsim_00.sv]]

if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts "XVLOG_FAIL"
  exit 2
}
puts $vlog_out

if {[catch {exec xelab tb_e2r_emb_rg_switch_cxsim_00 -s tb_e2r_emb_rg_switch_cxsim_00_sim -timescale 1ns/1ps} elab_out]} {
  puts $elab_out
  puts "XELAB_FAIL"
  exit 3
}
puts $elab_out

set logfile [file join $outdir xsim.log]
if {[catch {exec xsim tb_e2r_emb_rg_switch_cxsim_00_sim -runall} sim_out]} {
  set f [open $logfile w]
  puts $f $sim_out
  close $f
  puts $sim_out
  puts "XSIM_FAIL"
  exit 4
}
set f [open $logfile w]
puts $f $sim_out
close $f
puts $sim_out

if {[string match "*E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS*" $sim_out]} {
  puts "E2R_EMB_RG_SWITCH_CXSIM_00_OK"
  exit 0
}
if {[string match "*E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_FAIL*" $sim_out]} {
  puts "E2R_EMB_RG_SWITCH_CXSIM_00_FAIL"
  exit 5
}
puts "E2R_EMB_RG_SWITCH_CXSIM_00_NO_PASS"
exit 6
