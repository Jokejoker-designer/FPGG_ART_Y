# create_clock only — OOC / no board pins (engineering timing, not BOARD_PASS)
create_clock -period 10.000 -name clk [get_ports clk]
set_false_path -from [get_ports rst_n]
