# LM06-NTOK8-KNOWNNESS-DIFF-00. PROGRAM=NO. Core-only.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set src [list \
  [file join $root rtl/lm/a7lm06_pkg.sv] \
  [file join $root rtl/lm/isqrt32.sv] \
  [file join $root rtl/lm/floordiv_s48.sv] \
  [file join $root rtl/lm/weight_bram803k.sv] \
  [file join $root rtl/lm/weight_bram_tdp8.sv] \
  [file join $root rtl/lm/weight_tile803k.sv] \
  [file join $root rtl/lm/act_ram128k16.sv] \
  [file join $root rtl/lm/snap_ram4k16.sv] \
  [file join $root rtl/lm/tiny_gpt803k_core.sv] \
  [file join [pwd] tb_a7lm06_ntok8_diff.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag unit_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xvlog.log] r]]
  puts UNIT_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7lm06_ntok8_diff -s ntok8_s00 -timescale 1ns/1ps > [file join $bag unit_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xelab.log] r]]
  puts UNIT_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim ntok8_s00 -runall > [file join $bag unit_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag unit_xsim.log] r]]
}
set out [read [open [file join $bag unit_xsim.log] r]]
puts $out
if {![string match "*LM06_NTOK8_KNOWNNESS_DIFF_PASS*" $out]} {
  puts UNIT_XSIM_FAIL
  exit 5
}
puts NTOK8_XSIM_PASS
exit 0
