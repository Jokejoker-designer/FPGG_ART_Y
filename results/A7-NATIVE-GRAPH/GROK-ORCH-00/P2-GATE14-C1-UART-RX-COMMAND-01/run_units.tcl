# P2-GATE14-C1-UART-RX-COMMAND-01 units. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd [file join $root tests xsim]
set inc "-i [file join $root rtl/native_graph/control]"
proc sim {name srcs top snap pass} {
  global bag xvlog xelab xsim inc
  set vlog [file join $bag ${name}_xvlog.log]
  set elab [file join $bag ${name}_xelab.log]
  set simf [file join $bag ${name}_xsim.log]
  puts "=== $name ==="
  if {[catch {exec $xvlog -sv {*}$inc {*}$srcs > $vlog 2>@1}]} {
    puts [read [open $vlog r]]; puts "${name}_XVLOG_FAIL"; return 1
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > $elab 2>@1}]} {
    puts [read [open $elab r]]; puts "${name}_XELAB_FAIL"; return 1
  }
  catch {exec $xsim $snap -runall > $simf 2>@1}
  set out [read [open $simf r]]
  puts $out
  if {![string match "*${pass}*" $out]} { puts "${name}_XSIM_FAIL"; return 1 }
  puts "${name}_OK"
  return 0
}
set rx [file join $root rtl/board/a7ng_uart_rx100.sv]
set dec [file join $root rtl/native_graph/control/a7ng_gate14_uart_cmd_rx.sv]
set map [file join $root rtl/native_graph/control/a7ng_gate14_cmd_map.sv]
set f 0
incr f [sim UART_RX [list $rx [file join [pwd] tb_a7ng_uart_rx100.sv]] tb_a7ng_uart_rx100 g14rx UART_RX100_XSIM_PASS]
incr f [sim PARSER [list $dec [file join [pwd] tb_a7ng_gate14_parser.sv]] tb_a7ng_gate14_parser g14p GATE14_PARSER_RANDOM_XSIM_PASS]
incr f [sim AUTH [list $dec $map [file join [pwd] tb_a7ng_gate14_authority.sv]] tb_a7ng_gate14_authority g14a GATE14_COMMAND_AUTHORITY_XSIM_PASS]
if {$f} { puts UNIT_FAIL; exit 5 }
puts UNIT_ABC_PASS
exit 0
