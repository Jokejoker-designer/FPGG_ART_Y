# run_a7ng06_wide.tcl — NG-06R-WIDE: N_WAY ladder × ready bags
# Bags: ALWAYS_READY (control), SPARSE_READY (Bernoulli p=0.5), BURSTY_READY (64/64)
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH NG-06R-WIDE]
file mkdir $outdir
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} {
    # fall back to PATH
    set $tool [lindex [split $tool _] 0]
  }
}
if {![file exists $xvlog_bin]} { set xvlog_bin xvlog }
if {![file exists $xelab_bin]} { set xelab_bin xelab }
if {![file exists $xsim_bin]}  { set xsim_bin xsim }

set src [list \
    [file join $root rtl/native_graph/share a7ng_multi_agent_share.sv] \
    [file join $xsimdir tb_a7ng_wide_dispatch.sv]]

if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts XVLOG_FAIL
  exit 2
}
puts $vlog_out
set fh [open [file join $outdir xvlog_wide.log] w]
puts $fh $vlog_out
close $fh

# bag_tag → list of {way top logfile_suffix}
set bags [list always sparse bursty]
set ways {1 4 8 16}
set all_pass 1
set eng_pass 1

foreach bag $bags {
  switch $bag {
    always { set prefix tb_a7ng_wide_dispatch_way }
    sparse { set prefix tb_a7ng_wide_sparse_way }
    bursty { set prefix tb_a7ng_wide_bursty_way }
  }
  foreach way $ways {
    set top ${prefix}${way}
    puts "=== XSIM bag=$bag N_WAY=$way top=$top ==="
    if {[catch {exec $xelab_bin $top -s $top -timescale 1ns/1ps} elab_out]} {
      puts $elab_out
      puts "XELAB_FAIL bag=$bag way=$way"
      set all_pass 0
      set eng_pass 0
      continue
    }
    puts $elab_out
    set fh [open [file join $outdir xelab_${bag}_way${way}.log] w]
    puts $fh $elab_out
    close $fh

    if {[catch {exec $xsim_bin $top -runall} sim_out]} {
      puts $sim_out
      puts "XSIM_FAIL bag=$bag way=$way"
      set all_pass 0
      set eng_pass 0
      continue
    }
    puts $sim_out
    set fh [open [file join $outdir xsim_${bag}_way${way}.log] w]
    puts $fh $sim_out
    close $fh

    if {![string match "*A7NG06R_WIDE_XSIM_PASS*" $sim_out]} {
      puts "A7NG06R_WIDE_NO_PASS bag=$bag way=$way"
      set all_pass 0
      set eng_pass 0
    } else {
      puts "A7NG06R_WIDE_XSIM_OK bag=$bag way=$way"
    }
  }
}

# Keep legacy filenames for always way sims (compat with prior auditor paths)
foreach way $ways {
  set src_log [file join $outdir xsim_always_way${way}.log]
  set dst_log [file join $outdir xsim_way${way}.log]
  if {[file exists $src_log]} {
    file copy -force $src_log $dst_log
  }
}

if {!$all_pass} {
  puts A7NG06R_WIDE_LADDER_FAIL
  puts NG06R_WIDE_FAIL
  exit 5
}
puts A7NG06R_WIDE_XSIM_OK
puts A7NG06R_WIDE_LADDER_PASS
# ENGINEERING_PASS: all bags (ALWAYS+SPARSE+BURSTY) passed preregistered TB gates
puts NG06R_WIDE_ENGINEERING_PASS
