# NG-03 CDC — pure XDC (no Tcl if / remove_from_collection)
# 100 MHz fabric vs MIG PHY / ui clocks
set_clock_groups -asynchronous \
  -group [get_clocks -quiet sys_clk_pin] \
  -group [get_clocks -quiet -regexp {.*(c166|c200|ui|pll|mmcm|sys_clk_i|clk_ref).* }]
