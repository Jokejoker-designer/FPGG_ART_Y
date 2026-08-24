## A7-EAM-00B board. Pins + CFGBVS live in arty_a7_100.xdc (Digilent).
## Repeat config properties so bitstream DRC cannot miss them.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_false_path -from [get_ports btn[*]]
set_false_path -from [get_ports sw[*]]
