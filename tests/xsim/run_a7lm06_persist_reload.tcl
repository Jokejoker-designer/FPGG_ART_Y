set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set src [list \
    [file join $root rtl/lm a7lm06_pkg.sv] \
    [file join $root rtl/lm weight_bram_tdp8.sv] \
    [file join $root rtl/lm weight_tile803k.sv] \
    [file join $root rtl/lm lm06_persist.sv] \
    [file join $xsimdir tb_a7lm06_persist_reload.sv]]
if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec xelab tb_a7lm06_persist_reload -s tb_a7lm06pr -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec xsim tb_a7lm06pr -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7LM06_PERSIST_RELOAD_PASS*" $sim_out]} {
    puts "A7LM06_PERSIST_RELOAD_NO_PASS"
    exit 5
}
puts "A7LM06_PERSIST_RELOAD_OK"
