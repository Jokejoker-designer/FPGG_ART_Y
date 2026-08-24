# A7-EAM-01R OOC: 100 MHz core clock on eam01r_core.clk
create_clock -period 10.000 -name eam_clk [get_ports clk]
set_false_path -from [get_ports rst_n]
