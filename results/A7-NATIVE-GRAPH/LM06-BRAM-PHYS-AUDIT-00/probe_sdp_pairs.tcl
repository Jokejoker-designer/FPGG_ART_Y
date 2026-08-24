# Probe SDP pair reg_0 vs reg_1
set out_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $out_dir ../../..]]
open_checkpoint [file join $root_dir build/out/a7lm06_post_route.dcp]

foreach sample {
  {u_w/CH[0].ram0_reg_0}
  {u_w/CH[0].ram0_reg_1}
  {u_a/mem_reg_0}
  {u_a/mem_reg_1}
} {
  set c [get_cells -quiet $sample]
  puts "=== $sample REF=[get_property REF_NAME $c] MODE=[get_property RAM_MODE $c] RWA=[get_property READ_WIDTH_A $c] WWB=[get_property WRITE_WIDTH_B $c] ==="
  foreach p [lsort [get_pins -of_objects $c]] {
    set n [get_nets -quiet -of_objects $p]
    if {[llength $n]==0} continue
    set nn [get_property NAME [lindex $n 0]]
    set lf [lindex [split [get_property NAME $p] /] end]
    if {[string match DIP* $lf] || [string match DOP* $lf] || [string match DIADI* $lf] || [string match DOADO* $lf] || [string match CASCADE* $lf] || [string match CLK* $lf]} {
      if {[string match *<const* $nn] && ![string match DIP* $lf] && ![string match DOP* $lf] && ![string match CASCADE* $lf]} continue
      puts "  $lf -> $nn"
    }
  }
}
puts DONE
