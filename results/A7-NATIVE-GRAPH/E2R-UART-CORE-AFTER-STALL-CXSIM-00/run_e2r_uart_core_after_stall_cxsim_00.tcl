set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-UART-CORE-AFTER-STALL-CXSIM-00]
file mkdir $outdir
cd $outdir

set src [list [file join $xsimdir tb_e2r_uart_core_after_stall_cxsim_00.sv]]

if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts "XVLOG_FAIL"
  exit 2
}
puts $vlog_out

if {[catch {exec xelab tb_e2r_uart_core_after_stall_cxsim_00 -s tb_e2r_uart_core_after_stall_cxsim_00_sim -timescale 1ns/1ps} elab_out]} {
  puts $elab_out
  puts "XELAB_FAIL"
  exit 3
}
puts $elab_out

set logfile [file join $outdir xsim.log]
if {[catch {exec xsim tb_e2r_uart_core_after_stall_cxsim_00_sim -runall} sim_out]} {
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

if {[string match "*E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS*" $sim_out]} {
  puts "E2R_UART_CORE_AFTER_STALL_CXSIM_00_OK"
  exit 0
}
if {[string match "*E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_FAIL*" $sim_out]} {
  puts "E2R_UART_CORE_AFTER_STALL_CXSIM_00_FAIL"
  exit 5
}
puts "E2R_UART_CORE_AFTER_STALL_CXSIM_00_NO_PASS"
exit 6
