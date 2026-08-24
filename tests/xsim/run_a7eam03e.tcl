set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/eam a7eam03e_pkg.sv] \
    [file join $root rtl/eam eam03e_core.sv] \
    [file join $xsimdir tb_a7eam03e.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec xelab tb_a7eam03e -s tb_a7eam03e -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec xsim tb_a7eam03e -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7EAM03EA01T_XSIM_PASS*" $sim_out]} {
    puts "A7EAM03EA01T_XSIM_NO_PASS"
    exit 5
}
puts "A7EAM03EA01T_XSIM_OK"
