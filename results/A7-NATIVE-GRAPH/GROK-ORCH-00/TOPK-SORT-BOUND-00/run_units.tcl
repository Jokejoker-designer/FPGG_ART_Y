# TOPK-SORT-BOUND-00 unit TBs. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

proc run_one {bag root xvlog xelab xsim name top extra files marker} {
  set logp [file join $bag ${name}_]
  if {[catch {exec $xvlog -sv {*}$files > ${logp}xvlog.log 2>@1}]} {
    puts [read [open ${logp}xvlog.log r]]
    puts "${name}_XVLOG_FAIL"
    return 2
  }
  if {[catch {exec $xelab $top -s $name -timescale 1ns/1ps > ${logp}xelab.log 2>@1}]} {
    puts [read [open ${logp}xelab.log r]]
    puts "${name}_XELAB_FAIL"
    return 3
  }
  if {[catch {exec $xsim $name -runall > ${logp}xsim.log 2>@1}]} {
    puts [read [open ${logp}xsim.log r]]
  }
  set out [read [open ${logp}xsim.log r]]
  puts $out
  if {![string match "*${marker}*" $out]} {
    puts "${name}_FAIL"
    return 5
  }
  puts "${name}_OK"
  return 0
}

set pkg [file join $root rtl/native_graph/pkg/a7ng_pkg.sv]
set topk [file join $root rtl/native_graph/topk/a7ng_topk.sv]
set gbit [file join $root rtl/native_graph/topk/a7ng_topk_wavefront_global.sv]
set gmh  [file join $root rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv]
set lmh  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv]
set occ  [file join $bag g14_sort_occ_probe.sv]

set rc [run_one $bag $root $xvlog $xelab $xsim g14sb_count tb_g14_sort_bound_count {} [list $pkg $gmh $lmh $occ [file join $bag tb_g14_sort_bound_count.sv]] SORT_BOUND_COUNT_XSIM_PASS]
if {$rc} { exit $rc }

set rc [run_one $bag $root $xvlog $xelab $xsim g14sb_lgrp tb_g14_local_groups {} [list $pkg $topk $lmh $occ [file join $bag tb_g14_local_groups.sv]] LOCAL_GROUPS_XSIM_PASS]
if {$rc} { exit $rc }

set rc [run_one $bag $root $xvlog $xelab $xsim g14sb_gwaves tb_g14_global_waves {} [list $pkg $topk $gbit $gmh $occ [file join $bag tb_g14_global_waves.sv]] GLOBAL_WAVES_XSIM_PASS]
if {$rc} { exit $rc }

puts UNITS_ALL_OK
exit 0
