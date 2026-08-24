# Probe one RAMB36E1 pin/net topology from frozen LM06 DCP (READ_ONLY)
set out_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $out_dir ../../..]]
set dcp [file join $root_dir build/out/a7lm06_post_route.dcp]
open_checkpoint $dcp

foreach sample {
  {u_w/CH[0].ram0_reg_0}
  u_core/u_a/mem_reg_0_0
  u_core/u_snap/mem_reg_0
} {
  set c [get_cells -quiet $sample]
  if {[llength $c] == 0} {
    puts "MISSING $sample"
    continue
  }
  puts "=== CELL $sample ==="
  puts "REF [get_property REF_NAME $c] MODE [get_property RAM_MODE $c]"
  puts "RW_A [get_property READ_WIDTH_A $c] WW_B [get_property WRITE_WIDTH_B $c]"
  set pins [lsort [get_pins -of_objects $c]]
  puts "PIN_COUNT [llength $pins]"
  set fh [open [file join $out_dir "pins_[string map {/ _ [ _ ] _} $sample].txt"] w]
  foreach p $pins {
    set n [get_nets -quiet -of_objects $p]
    set nn ""
    if {[llength $n]} { set nn [get_property NAME [lindex $n 0]] }
    set dir [get_property DIRECTION $p]
    puts $fh "[get_property NAME $p]\t$dir\t$nn"
  }
  close $fh
  puts "WROTE pins for $sample"
}

# Also report_ram_utilization snippet if available
catch {report_ram_utilization -file [file join $out_dir report_ram_utilization.rpt] -return_string} msg
puts "RAM_UTIL_STATUS $msg"
puts "PROBE_DONE"
