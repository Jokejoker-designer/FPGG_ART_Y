set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}
set src [list \
    [file join $root rtl/native_graph/memory a7ng_epoch_mgr.sv] \
    [file join $root rtl/native_graph/memory a7ng_wm_authority.sv] \
    [file join $root rtl/native_graph/memory a7ng_learned_gen_view.sv] \
    [file join $root rtl/native_graph/memory a7ng_reset_ctrl.sv] \
    [file join $root rtl/native_graph/memory a7ng_reset_verify.sv] \
    [file join $root rtl/native_graph/memory a7ng_reset00_top.sv] \
    [file join $xsimdir tb_a7ng_reset00.sv]]
if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec $xelab_bin tb_a7ng_reset00 -s tb_a7ng_reset00 -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec $xsim_bin tb_a7ng_reset00 -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG_RESET00_XSIM_PASS*" $sim_out]} { puts A7NG_RESET00_NO_PASS; exit 5 }
puts A7NG_RESET00_XSIM_OK
