# Dual-clock WDMA release CDC unit. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set src [list \
  [file join $root rtl/board/a7ng_wdma_rel_sync.sv] \
  [file join [pwd] tb_a7ng_wdma_rel_sync.sv] \
]
if {[catch {exec $xvlog -sv {*}$src > [file join $bag cdc_xvlog.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xvlog.log] r]]
  puts CDC_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xelab tb_a7ng_wdma_rel_sync -s wdma_rel -timescale 1ns/1ps > [file join $bag cdc_xelab.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xelab.log] r]]
  puts CDC_XELAB_FAIL
  exit 3
}
if {[catch {exec $xsim wdma_rel -runall > [file join $bag cdc_xsim.log] 2>@1}]} {
  puts [read [open [file join $bag cdc_xsim.log] r]]
}
set out [read [open [file join $bag cdc_xsim.log] r]]
puts $out
if {![string match "*WDMA_REL_CDC_XSIM_PASS*" $out]} {
  puts CDC_XSIM_FAIL
  exit 5
}
puts WDMA_REL_CDC_UNIT_PASS
exit 0
