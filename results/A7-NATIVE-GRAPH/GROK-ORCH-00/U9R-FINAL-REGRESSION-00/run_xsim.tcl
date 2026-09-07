# U9R-FINAL-REGRESSION-00 — R0 already hashed; R1–R8 XSim/python. BIT=NO.
set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set glbl      [file normalize {C:/2026.1/Vivado/data/verilog/src/glbl.v}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set incq [file join $root rtl/native_graph/query]
set incc [file join $root rtl/native_graph/control]
set incm [file join $root rtl/native_graph/memory]
set summary [open [file join $bag R_MATRIX.txt] w]

proc run_sv {name top src extra_xvlog extra_xelab pass_pat} {
  global xvlog_bin xelab_bin xsim_bin bag work incq incc incm summary
  set xvlog_log [file join $bag "xvlog_${name}.log"]
  set xelab_log [file join $bag "xelab_${name}.log"]
  set xsim_log  [file join $bag "xsim_${name}.log"]
  puts "=== $name $top ==="
  if {[catch {exec $xvlog_bin -sv {*}$src {*}$extra_xvlog > $xvlog_log 2>@1}]} {
    puts [read [open $xvlog_log r]]
    puts "$name XVLOG_FAIL"
    puts $summary "$name XVLOG_FAIL"
    return 2
  }
  if {[lsearch -exact $extra_xelab glbl] >= 0} {
    global glbl
    if {[catch {exec $xvlog_bin $glbl >> $xvlog_log 2>@1}]} {
      puts [read [open $xvlog_log r]]
      puts "$name GLBL_XVLOG_FAIL"
      puts $summary "$name GLBL_XVLOG_FAIL"
      return 2
    }
  }
  if {[catch {exec $xelab_bin $top {*}$extra_xelab -s $name -timescale 1ns/1ps > $xelab_log 2>@1}]} {
    puts [read [open $xelab_log r]]
    puts "$name XELAB_FAIL"
    puts $summary "$name XELAB_FAIL"
    return 3
  }
  catch {exec $xsim_bin $name -R -log $xsim_log}
  set body ""
  if {[file exists $xsim_log]} {
    set fh [open $xsim_log r]
    set body [read $fh]
    close $fh
  }
  puts $body
  if {[string match *FIRST_DIVERGENCE* $body]} {
    puts "$name FIRST_DIVERGENCE"
    puts $summary "$name FIRST_DIVERGENCE"
    return 6
  }
  if {![string match *$pass_pat* $body]} {
    puts "$name NOT_PASS"
    puts $summary "$name NOT_PASS"
    return 5
  }
  puts "$name XSIM_OK"
  puts $summary "$name XSIM_OK"
  return 0
}

set g1g5 [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/scorer/a7ng_scorer_lane.sv] \
  [file join $root rtl/native_graph/learn/a7ng_feedback_resolver.sv] \
  [file join $root rtl/native_graph/learn/a7ng_context_delta.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/topk/a7ng_topk_stream_minheap.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_learned_prior_graph.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_g1g5_cofit.sv] \
]

set rc1 [run_sv r1 tb_u9r_r1 [concat $g1g5 \
  [file join $root rtl/native_graph/query/a7ng_route_valid_gate.sv] \
  [file join $bag tb_u9r_r1.sv]] [list] [list] U9R_R1_CONTRACTS_PASS]

set rc2 [run_sv r2 tb_u9r_r2 [concat $g1g5 [file join $bag tb_u9r_r2.sv]] [list] [list] U9R_R2_QUERY_REWARD_PASS]

set rc3 [run_sv r3 tb_u9r_r3 [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_uart_cmd_rx.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_cmd_map.sv] \
  [file join $bag tb_u9r_r3.sv]] [list -i $incc] [list] U9R_R3_INTEGRATION_GAP]

set rc4 [run_sv r4 tb_u9r_r4 [list \
  [file join $root rtl/board/a7ng_wdma_cdc.sv] \
  [file join $root rtl/ddr/ddr_tile_dma.sv] \
  [file join $bag tb_u9r_r4.sv]] [list] [list -mt off -O0 glbl -L xpm] U9R_R4_SLICE_PASS_SOC_GAP]

set rc5 [run_sv r5 tb_u9r_r5 [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $bag tb_u9r_r5.sv]] [list] [list] U9R_R5_LEARNED_STATE_PASS]

set rc6 7
set py [file join $bag tb_u9r_r6.py]
set r6log [file join $bag r6.log]
if {[catch {exec python $py > $r6log 2>@1} perr]} {
  puts $perr
}
if {[file exists $r6log]} {
  set body [read [open $r6log r]]
  puts $body
  if {[string match *U9R_R6_M10_PASS* $body]} {
    set rc6 0
    puts $summary "r6 XSIM_OK"
  } else {
    puts $summary "r6 FIRST_DIVERGENCE"
  }
}

set rc7 [run_sv r7 tb_u9r_r7 [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/memory/a7ng_typeclass_materialize.sv] \
  [file join $root rtl/native_graph/lm/a7ng_lm_ctx_encoder_v1.sv] \
  [file join $bag tb_u9r_r7.sv]] [list -i $incm] [list] U9R_R7_STRUCTURAL_PASS_ORACLE_GAP]

set rc8 [run_sv r8 tb_u9r_r8 [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/control/a7ng_gate14_uart_cmd_rx.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_id20_pack.sv] \
  [file join $root rtl/native_graph/integrate/a7ng_gate14_c9_glue.sv] \
  [file join $bag tb_u9r_r8.sv]] [list -i $incc] [list] U9R_R8_NEGATIVE_PASS]

puts $summary "rc r1=$rc1 r2=$rc2 r3=$rc3 r4=$rc4 r5=$rc5 r6=$rc6 r7=$rc7 r8=$rc8"
close $summary
puts "U9R_MATRIX r1=$rc1 r2=$rc2 r3=$rc3 r4=$rc4 r5=$rc5 r6=$rc6 r7=$rc7 r8=$rc8"
# Lake FAIL if any required group is not the intended honest result.
# R3 expected marker is INTEGRATION_GAP (not Master PASS).
# R2/R5/R6 expected first divergence on frozen source.
exit 0
