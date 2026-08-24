## A7-EAM-01R board. Pins + CFGBVS live in arty_a7_100.xdc (Digilent).
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_false_path -from [get_ports btn[*]]
set_false_path -from [get_ports sw[*]]
