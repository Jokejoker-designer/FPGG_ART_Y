set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/native_graph/memory a7ng_bram_hotset.sv] \
    [file join $xsimdir tb_a7ng_hotset.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec xelab tb_a7ng_hotset -s tb_a7ng_hotset -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec xsim tb_a7ng_hotset -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG03_HOTSET_XSIM_PASS*" $sim_out]} { puts A7NG03_HOTSET_XSIM_NO_PASS; exit 5 }
puts A7NG03_HOTSET_XSIM_OK
