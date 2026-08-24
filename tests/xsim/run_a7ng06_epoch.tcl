# run_a7ng06_epoch.tcl — NG-06R-EPOCH mixed-epoch DROP_STALE bags
# Units = seed bags (share ×3 + prune ×2), each HORIZON=100000 cycles
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH NG-06R-EPOCH]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
if {![file exists $xvlog_bin]} { set xvlog_bin xvlog }
if {![file exists $xelab_bin]} { set xelab_bin xelab }
if {![file exists $xsim_bin]}  { set xsim_bin xsim }

set src [list \
    [file join $root rtl/native_graph/share a7ng_multi_agent_share.sv] \
    [file join $root rtl/native_graph/prune a7ng_ctx_prune.sv] \
    [file join $xsimdir tb_a7ng_epoch.sv] \
    [file join $xsimdir tb_a7ng_ctx_prune.sv]]

if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts XVLOG_FAIL
  exit 2
}
puts $vlog_out
set fh [open [file join $outdir xvlog_epoch.log] w]
puts $fh $vlog_out
close $fh

set tops [list \
  tb_a7ng_epoch \
  tb_a7ng_epoch_share_seed1 \
  tb_a7ng_epoch_share_seed2 \
  tb_a7ng_epoch_prune_seed1 \
  tb_a7ng_ctx_prune]

set all_pass 1
foreach top $tops {
  puts "=== XSIM top=$top ==="
  if {[catch {exec $xelab_bin $top -s $top -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL top=$top"
    set all_pass 0
    continue
  }
  puts $elab_out
  set fh [open [file join $outdir xelab_${top}.log] w]
  puts $fh $elab_out
  close $fh

  if {[catch {exec $xsim_bin $top -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL top=$top"
    set all_pass 0
    continue
  }
  puts $sim_out
  set fh [open [file join $outdir xsim_${top}.log] w]
  puts $fh $sim_out
  close $fh

  if {$top eq "tb_a7ng_ctx_prune"} {
    if {![string match "*A7NG04_PRUNE_PASS*" $sim_out]} {
      puts "A7NG04_PRUNE_NO_PASS"
      set all_pass 0
    }
  } else {
    if {![string match "*A7NG06R_EPOCH_XSIM_PASS*" $sim_out]} {
      puts "A7NG06R_EPOCH_NO_PASS top=$top"
      set all_pass 0
    } else {
      puts "A7NG06R_EPOCH_XSIM_OK top=$top"
    }
  }
}

if {!$all_pass} {
  puts A7NG06R_EPOCH_FAIL
  exit 5
}
puts A7NG06R_EPOCH_XSIM_OK
puts NG06R_EPOCH_ENGINEERING_PASS
