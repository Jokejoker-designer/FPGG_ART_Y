## A7-LM-06: 803k core + UART at 50 MHz. Pins stay in arty_a7_100.xdc.
create_generated_clock -name clk50 -source [get_ports CLK100MHZ] -divide_by 2 [get_pins u_div/u_buf/O]
set_false_path -from [get_clocks clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks clk50] -from [get_clocks -quiet *pll*]
