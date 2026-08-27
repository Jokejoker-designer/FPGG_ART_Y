# program_flash_wmem_t2.tcl — erase+program wmem.bin at flash offset 0x400000
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set outdir     [file join $root_dir results A7-NATIVE-GRAPH E2R-T2-SPI-WMEM-00]
set binfile    [file join $outdir a7lm06_wmem.bin]
set mcsfile    [file join $outdir wmem_at_0x400000.mcs]
set want_jtag  210319BE776E

if {![file exists $binfile]} {
  puts stderr "ERROR: missing $binfile"
  exit 2
}

puts "=== write_cfgmem MCS (data @ 0x400000) ==="
write_cfgmem -force -format mcs -size 16 -interface SPIx4 \
  -loaddata "up 0x400000 $binfile" $mcsfile

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set tgt [current_hw_target]
puts "HW_TARGET=$tgt"
if {![string match "*$want_jtag*" $tgt]} {
  # try explicit match among targets
  set found 0
  foreach t [get_hw_targets] {
    if {[string match "*$want_jtag*" $t]} {
      close_hw_target
      open_hw_target $t
      set tgt $t
      set found 1
      break
    }
  }
  if {!$found} {
    puts stderr "REFUSE: JTAG matching $want_jtag not found (got $tgt)"
    exit 4
  }
}

current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
refresh_hw_device [current_hw_device]

# Digilent Arty A7-100T: S25FL128S
create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {s25fl128sxxxxxx0-spi-x1_x2_x4}] 0]
set cfgmem [get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.ADDRESS_RANGE  {use_file} $cfgmem
set_property PROGRAM.FILES [list $mcsfile] $cfgmem
set_property PROGRAM.PRM_FILE {} $cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $cfgmem
set_property PROGRAM.BLANK_CHECK  0 $cfgmem
set_property PROGRAM.ERASE        1 $cfgmem
set_property PROGRAM.CFG_PROGRAM  1 $cfgmem
set_property PROGRAM.VERIFY       1 $cfgmem
set_property PROGRAM.CHECKSUM     0 $cfgmem

create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]

puts "=== program_hw_cfgmem (may take several minutes) ==="
program_hw_cfgmem -hw_cfgmem $cfgmem
puts "FLASH_WMEM_PROGRAM_PASS mcs=$mcsfile offset=0x400000 jtag=$tgt"
exit 0
