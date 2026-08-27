## Arty A7 Quad-SPI flash — Digilent Arty-A7-100-Master.xdc + SCK L16 (user GPIO tap)
## Used by T2-SPI wmem boot after configuration.
set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33 } [get_ports { qspi_cs_n }];  # FCS_B
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { qspi_sck }];   # SCK (user tap)
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports { qspi_mosi }];  # DQ0 / MOSI
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports { qspi_miso }];  # DQ1 / MISO
set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq2 }];   # DQ2 / WP#
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq3 }];   # DQ3 / HOLD#
set_property PULLUP true [get_ports { qspi_miso }]
