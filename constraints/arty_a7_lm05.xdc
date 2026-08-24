## A7-LM-05: 399k core + UART at 50 MHz. Pins stay in arty_a7_100.xdc.
## MIG / ui_clk stay in mig_7series_0.xdc + a7lm01_cdc.xdc.
create_generated_clock -name clk50 -source [get_ports CLK100MHZ] -divide_by 2 [get_pins u_div/u_buf/O]
## Persist + tile-W handshake + UART/status CDC. Do not time clk50 against MIG ui/pll.
set_false_path -from [get_clocks clk50] -to [get_clocks -quiet *ui*]
set_false_path -to [get_clocks clk50] -from [get_clocks -quiet *ui*]
set_false_path -from [get_clocks clk50] -to [get_clocks -quiet *pll*]
set_false_path -to [get_clocks clk50] -from [get_clocks -quiet *pll*]
