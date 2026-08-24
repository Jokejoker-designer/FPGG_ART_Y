set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/eam a7eam00_pkg.sv] \
    [file join $root rtl/eam a7eam01r_pkg.sv] \
    [file join $root rtl/eam eam_tdp256.sv] \
    [file join $root rtl/eam eam01r_ibank.sv] \
    [file join $root rtl/eam eam01r_core.sv] \
    [file join $root rtl/eam eam02q_q1.sv] \
    [file join $xsimdir tb_a7eam02q.sv]]
set inc [file join $root rtl/eam]
set inc2 $xsimdir
if {[catch {exec xvlog -sv -i $inc -i $inc2 {*}$src} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec xelab tb_a7eam02q -s tb_a7eam02q -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec xsim tb_a7eam02q -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7EAM02Q_XSIM_PASS*" $sim_out]} {
    puts "A7EAM02Q_XSIM_NO_PASS"
    exit 5
}
puts "A7EAM02Q_XSIM_OK"
