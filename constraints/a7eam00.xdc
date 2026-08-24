# A7-EAM-00S: 100 MHz core clock. I/O delays applied in the build Tcl
# after synth (XDC cannot use remove_from_collection during synth parse).
create_clock -period 10.000 -name eam_clk [get_ports clk]
set_false_path -from [get_ports rst_n]
