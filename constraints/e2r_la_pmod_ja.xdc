## E2R-LA-PMOD-00 — Pmod JA observe (Arty A7-100T, 3.3 V LVCMOS)
## JA1..JA4 = ja[0..3], JA7..JA10 = ja[4..7]. Pin 5/11 = GND. Do not drive VCC from LA.
set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[0] }]
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[1] }]
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[2] }]
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[3] }]
set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[4] }]
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[5] }]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[6] }]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports { ja[7] }]
set_false_path -to [get_ports { ja[*] }]
