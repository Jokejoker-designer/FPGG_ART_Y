set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/lm a7lm06_pkg.sv] \
    [file join $root rtl/lm isqrt32.sv] \
    [file join $root rtl/lm floordiv_s48.sv] \
    [file join $root rtl/lm weight_bram803k.sv] \
    [file join $root rtl/lm weight_bram_tdp8.sv] \
    [file join $root rtl/lm weight_tile803k.sv] \
    [file join $root rtl/lm act_ram128k16.sv] \
    [file join $root rtl/lm snap_ram4k16.sv] \
    [file join $root rtl/lm tiny_gpt803k_core.sv] \
    [file join $xsimdir tb_a7lm06_core.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec xelab tb_a7lm06_core -s tb_a7lm06 -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec xsim tb_a7lm06 -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7LM06_XSIM_PASS*" $sim_out]} {
    puts "A7LM06_XSIM_NO_PASS"
    exit 5
}
puts "A7LM06_XSIM_OK"
