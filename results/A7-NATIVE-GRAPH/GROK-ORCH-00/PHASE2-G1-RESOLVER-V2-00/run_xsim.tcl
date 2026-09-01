# PHASE2-G1-RESOLVER-V2-00 XSim. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
set rtl   [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv]
cd [file join $root tests xsim]

proc run_one {xvlog xelab xsim rtl tb top snap bag tag pass} {
  if {[catch {exec $xvlog -sv $rtl [file join [pwd] $tb] > [file join $bag ${tag}_xvlog.log] 2>@1}]} {
    puts [read [open [file join $bag ${tag}_xvlog.log] r]]
    puts "${tag}_XVLOG_FAIL"
    return 2
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > [file join $bag ${tag}_xelab.log] 2>@1}]} {
    puts [read [open [file join $bag ${tag}_xelab.log] r]]
    puts "${tag}_XELAB_FAIL"
    return 3
  }
  if {[catch {exec $xsim $snap -runall > [file join $bag ${tag}_xsim.log] 2>@1}]} {
    puts [read [open [file join $bag ${tag}_xsim.log] r]]
  }
  set out [read [open [file join $bag ${tag}_xsim.log] r]]
  puts $out
  if {![string match "*${pass}*" $out]} {
    puts "${tag}_XSIM_FAIL"
    return 5
  }
  puts "${tag}_OK"
  return 0
}

set e 0
set r [run_one $xvlog $xelab $xsim $rtl tb_a7ng_feedback_resolver.sv tb_a7ng_feedback_resolver fb_res_v2 $bag unit FEEDBACK_RESOLVER_UNIT_XSIM_PASS]
if {$r} { set e $r }
set r [run_one $xvlog $xelab $xsim $rtl tb_resolver_counterexample.sv tb_resolver_counterexample cx_res_v2 $bag cx RESOLVER_COUNTEREXAMPLE_XSIM_PASS]
if {$r} { set e $r }
set r [run_one $xvlog $xelab $xsim $rtl tb_a7ng_feedback_resolver_v2_rand.sv tb_a7ng_feedback_resolver_v2_rand v2_rand $bag rand RESOLVER_V2_RAND_XSIM_PASS]
if {$r} { set e $r }
if {$e} { exit $e }
puts "RESOLVER_V2_ALL_XSIM_PASS"
exit 0
