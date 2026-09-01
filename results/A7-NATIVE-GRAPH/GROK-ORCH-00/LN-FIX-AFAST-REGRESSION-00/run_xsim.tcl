# LN-FIX-AFAST-REGRESSION-00. PROGRAM=NO. A/B old vs patched core. No bit/P&R.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set lm [list \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
]
set tb [file join [pwd] tb_a7lm06_afast_lnfix_regression.sv]

proc run_arm {core tag define} {
  global bag root xvlog xelab xsim lm tb
  set src [concat $lm [list $core $tb]]
  set vlog [file join $bag unit_xvlog_${tag}.log]
  set elab [file join $bag unit_xelab_${tag}.log]
  set sim  [file join $bag unit_xsim_${tag}.log]
  if {$define eq ""} {
    set xvcmd [list $xvlog -sv {*}$src]
  } else {
    set xvcmd [list $xvlog -sv -d $define {*}$src]
  }
  if {[catch {exec {*}$xvcmd > $vlog 2>@1}]} {
    puts [read [open $vlog r]]
    puts UNIT_XVLOG_FAIL_$tag
    return 2
  }
  if {[catch {exec $xelab tb_a7lm06_afast_lnfix_regression -s afast_${tag} -timescale 1ns/1ps > $elab 2>@1}]} {
    puts [read [open $elab r]]
    puts UNIT_XELAB_FAIL_$tag
    return 3
  }
  if {[catch {exec $xsim afast_${tag} -runall > $sim 2>@1}]} {
    puts [read [open $sim r]]
  }
  set out [read [open $sim r]]
  puts "===== ARM $tag ====="
  puts $out
  if {![string match "*LN_FIX_AFAST_REGRESSION_PASS*" $out]} {
    puts UNIT_XSIM_FAIL_$tag
    return 5
  }
  return 0
}

set oldc [file join $bag tiny_gpt803k_core_OLD.sv]
set newc [file join $root rtl/lm/tiny_gpt803k_core.sv]
set e1 [run_arm $oldc old ARM_OLD]
set e2 [run_arm $newc new ""]
if {$e1 != 0 || $e2 != 0} {
  puts AFAST_AB_FAIL
  exit 5
}
puts AFAST_AB_XSIM_DONE
exit 0
