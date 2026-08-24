# TermGen 16-lane feature gen XSim. Law a7ng-termgen-v0.
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
    if {![file exists [set $tool]]} {
        puts "MISSING_[string toupper $tool]"
        exit 9
    }
}

# Refresh golden include from Python oracle
if {[catch {exec python [file join $xsimdir termgen_oracle.py]} py_out]} {
    puts $py_out
    puts "TERMGEN_ORACLE_FAIL"
    exit 1
}
puts $py_out
if {![string match "*TERMGEN_PY_PASS*" $py_out]} {
    puts "TERMGEN_PY_NO_PASS"
    exit 1
}

set src [list \
    [file join $root rtl/native_graph/pkg a7ng_pkg.sv] \
    [file join $root rtl/native_graph/scorer a7ng_termgen_lane.sv] \
    [file join $root rtl/native_graph/scorer a7ng_termgen_array.sv] \
    [file join $xsimdir tb_a7ng_termgen.sv]]
if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec $xelab_bin tb_a7ng_termgen -s tb_a7ng_termgen -timescale 1ns/1ps} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec $xsim_bin tb_a7ng_termgen -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7NG_TERMGEN_XSIM_PASS*" $sim_out]} {
    puts "A7NG_TERMGEN_XSIM_NO_PASS"
    exit 5
}
puts "A7NG_TERMGEN_XSIM_OK"
