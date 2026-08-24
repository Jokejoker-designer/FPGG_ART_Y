set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/native_graph/share a7ng_multi_agent_share.sv] \
    [file join $xsimdir tb_a7ng_multi_agent_share.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec xelab tb_a7ng_multi_agent_share -s tb_a7ng_multi_agent_share -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec xsim tb_a7ng_multi_agent_share -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG06_SHARE_XSIM_PASS*" $sim_out]} { puts A7NG06_SHARE_NO_PASS; exit 5 }
puts A7NG06_SHARE_XSIM_OK
