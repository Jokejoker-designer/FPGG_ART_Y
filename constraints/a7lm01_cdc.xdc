# UART @ 100 MHz is asynchronous to MIG ui_clk (~83.3 MHz) and 166/200 MHz PHY clocks.
set uart_clk [get_clocks -quiet sys_clk_pin]
if {$uart_clk eq ""} {
    set uart_clk [get_clocks -of_objects [get_ports CLK100MHZ]]
}
set other [remove_from_collection [all_clocks] $uart_clk]
if {[llength $other] && [llength $uart_clk]} {
    set_clock_groups -asynchronous -group $uart_clk -group $other
}
