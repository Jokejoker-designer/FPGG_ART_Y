set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root rtl/native_graph/memory a7ng_axi_mem_model.sv] \
    [file join $root rtl/native_graph/learn a7ng_prior_persist.sv] \
    [file join $xsimdir tb_a7ng_prior_persist.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec xelab tb_a7ng_prior_persist -s tb_a7ng_prior_persist -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec xsim tb_a7ng_prior_persist -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG05_PERSIST_XSIM_PASS*" $sim_out]} { puts A7NG05_PERSIST_NO_PASS; exit 5 }
puts A7NG05_PERSIST_XSIM_OK
