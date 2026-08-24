# Post-route functional sim of tiny_gpt25k_core vs the same one-full TB.
# Funcsim (not timesim): catches inferred-RAM vs RTL, not delay-X.
# Does not write arty_a7_lm03.bit and does not program the board.
set script_dir [file normalize [file dirname [info script]]]
set root [file normalize [file join $script_dir ../..]]
set xsimdir [file join $root tests xsim]
set out_dir [file join $root build out]
set build_dir [file join $root build vivado_a7lm03_core_pr]
file mkdir $out_dir
file mkdir $build_dir

set part_name xc7a100tcsg324-1
create_project -force a7lm03_core_pr $build_dir -part $part_name
set_property target_language Verilog [current_project]
set_property verilog_define {SYNTHESIS A7LM03_NETLIST} [current_fileset]

add_files -norecurse [list \
    [file join $root rtl lm a7lm03_pkg.sv] \
    [file join $root rtl lm isqrt32.sv] \
    [file join $root rtl lm floordiv_s48.sv] \
    [file join $root rtl lm weight_bram25k.sv] \
    [file join $root rtl lm act_ram32k.sv] \
    [file join $root rtl lm tiny_gpt25k_core.sv]]
set_property top tiny_gpt25k_core [current_fileset]
update_compile_order -fileset sources_1

puts "=== SYNTH+IMPL tiny_gpt25k_core (OOC) ==="
synth_design -top tiny_gpt25k_core -part $part_name -mode out_of_context -flatten_hierarchy rebuilt
opt_design
place_design
route_design
write_checkpoint -force [file join $out_dir a7lm03_core_post_route.dcp]
write_verilog -mode funcsim -force [file join $out_dir a7lm03_core_pr_funcsim.v]

set net [file join $out_dir a7lm03_core_pr_funcsim.v]
set tb  [file join $xsimdir tb_a7lm03_core.sv]
set glbl C:/2026.1/Vivado/data/verilog/src/glbl.v
puts "=== XSIM post-route funcsim ==="
cd $xsimdir
set pkg [file join $root rtl lm a7lm03_pkg.sv]
if {[catch {exec xvlog -sv -d A7LM03_NETLIST -d SYNTHESIS $pkg $net $tb $glbl} vlog_out]} {
    puts $vlog_out
    puts "XVLOG_FAIL"
    exit 2
}
puts $vlog_out
if {[catch {exec xelab tb_a7lm03_core glbl -s tb_a7lm03_pr -timescale 1ns/1ps -L unisims_ver -L unimacro_ver -L simprims_ver} elab_out]} {
    puts $elab_out
    puts "XELAB_FAIL"
    exit 3
}
puts $elab_out
if {[catch {exec xsim tb_a7lm03_pr -runall} sim_out]} {
    puts $sim_out
    puts "XSIM_FAIL"
    exit 4
}
puts $sim_out
if {![string match "*A7LM03_XSIM_PASS*" $sim_out]} {
    puts "POST_ROUTE_NO_PASS"
    exit 5
}
puts "A7LM03_POST_ROUTE_OK"
