# Behavioral xsim for A7-LM-03 core. Does not write bitstreams.
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl lm a7lm03_pkg.sv] \
    [file join $root rtl lm isqrt32.sv] \
    [file join $root rtl lm floordiv_s48.sv] \
    [file join $root rtl lm weight_bram25k.sv] \
    [file join $root rtl lm act_ram32k.sv] \
    [file join $root rtl lm tiny_gpt25k_core.sv] \
    [file join $xsimdir tb_a7lm03_core.sv]]
catch {exec xvlog -sv {*}$src} vlog_out
puts $vlog_out
if {[catch {exec xelab tb_a7lm03_core -s tb_a7lm03 -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 2
}
puts $elab_out
if {[catch {exec xsim tb_a7lm03 -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 3
}
puts $sim_out
if {![string match "*A7LM03_XSIM_PASS*" $sim_out]} {
    puts "XSIM_NO_PASS"
    exit 4
}
puts "A7LM03_XSIM_OK"
