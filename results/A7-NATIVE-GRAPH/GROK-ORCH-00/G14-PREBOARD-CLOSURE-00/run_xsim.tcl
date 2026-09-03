# G14-PREBOARD-CLOSURE-00 epoch identity XSim. PROGRAM=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog {C:/2026.1/Vivado/bin/xvlog.bat}
set xelab {C:/2026.1/Vivado/bin/xelab.bat}
set xsim  {C:/2026.1/Vivado/bin/xsim.bat}
cd $bag
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}

proc run_one {top snap srcs marker} {
  global xvlog xelab xsim bag
  set xvlog_log [file join $bag ${snap}_xvlog.log]
  set xelab_log [file join $bag ${snap}_xelab.log]
  set xsim_log  [file join $bag ${snap}_xsim.log]
  if {[catch {exec $xvlog -sv {*}$srcs > $xvlog_log 2>@1}]} {
    puts [read [open $xvlog_log r]]
    puts "${snap}_XVLOG_FAIL"
    return 2
  }
  if {[catch {exec $xelab $top -s $snap -timescale 1ns/1ps > $xelab_log 2>@1}]} {
    puts [read [open $xelab_log r]]
    puts "${snap}_XELAB_FAIL"
    return 3
  }
  if {[catch {exec $xsim $snap -runall > $xsim_log 2>@1}]} {
    puts [read [open $xsim_log r]]
  }
  set out [read [open $xsim_log r]]
  puts $out
  if {($marker ne "") && ![string match "*${marker}*" $out]} {
    puts "${snap}_XSIM_FAIL"
    return 5
  }
  return 0
}

set epoch_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $bag tb_a7ng_epoch_identity.sv] \
]
set pboot_src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root results/A7-NATIVE-GRAPH/GROK-ORCH-00/G14-DOWNSTREAM-P0-GEN-BOOT-00/tb_a7ng_pboot_dirty_ddr.sv] \
]

set rc [run_one tb_a7ng_epoch_identity epoch_id $epoch_src "EPOCH_IDENTITY_XSIM_PASS"]
if {$rc != 0} { exit $rc }
set rc [run_one tb_a7ng_pboot_dirty_ddr pboot_reg $pboot_src "PBOOT_DIRTY_DDR_XSIM_PASS"]
if {$rc != 0} { exit $rc }
puts EPOCH_ROOT_XSIM_RAN
exit 0
