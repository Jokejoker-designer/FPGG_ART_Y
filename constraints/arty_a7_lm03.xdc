## A7-LM-03 only. Pins stay in arty_a7_100.xdc (unmodified).
## Sequential 25K core is 50 MHz (divide-by-2 from the 100 MHz pin).
create_generated_clock -name clk50 -source [get_ports CLK100MHZ] -divide_by 2 [get_pins u_div/u_buf/O]
