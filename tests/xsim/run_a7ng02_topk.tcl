set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set vec [file join $root results/A7-NATIVE-GRAPH/NG-02R-TOPK/vectors/topk_100k.txt]
if {![file exists $vec]} {
  puts "VEC_MISSING generating..."
  if {[catch {exec python [file join $xsimdir ng02r_topk_oracle.py] --out $vec} gen_out]} {
    puts $gen_out
    puts VEC_GEN_FAIL
    exit 6
  }
  puts $gen_out
}
set src [list \
    [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root rtl/native_graph/topk a7ng_topk.sv] \
    [file join $xsimdir tb_a7ng_topk.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec xelab tb_a7ng_topk -s tb_a7ng_topk -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
# TB default VEC path is ../../results/.../topk_100k.txt (relative to tests/xsim)
if {[catch {exec xsim tb_a7ng_topk -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG02R_TOPK_XSIM_PASS*" $sim_out]} { puts A7NG02R_TOPK_XSIM_NO_PASS; exit 5 }
puts A7NG02R_TOPK_XSIM_OK
