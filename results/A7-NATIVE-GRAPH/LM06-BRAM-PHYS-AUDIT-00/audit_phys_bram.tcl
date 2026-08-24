# LM06-BRAM-PHYS-AUDIT-00 — full physical audit with 7-series pin names (READ_ONLY)
set out_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $out_dir ../../..]]
set dcp [file join $root_dir build/out/a7lm06_post_route.dcp]
set phys_tsv [file join $out_dir BRAM_PHYSICAL.tsv]
set group_tsv [file join $out_dir BRAM_CONTROL_GROUPS.tsv]

proc leaf {pin} {
  set n [get_property NAME $pin]
  set i [string last / $n]
  if {$i < 0} { return $n }
  return [string range $n [expr {$i+1}] end]
}

proc net_of {pin} {
  set n [get_nets -quiet -of_objects $pin]
  if {[llength $n] == 0} { return "" }
  return [get_property NAME [lindex $n 0]]
}

proc is_const_net {nn} {
  if {$nn eq ""} { return 1 }
  if {[string match *<const0>* $nn]} { return 1 }
  if {[string match *<const1>* $nn]} { return 1 }
  if {[string match */GND* $nn]} { return 1 }
  if {[string match */VCC* $nn]} { return 1 }
  return 0
}

proc owner_of {cell} {
  foreach p [split $cell /] {
    if {$p eq "u_w" || $p eq "u_a" || $p eq "u_snap"} { return $p }
  }
  return "other"
}

# Classify DIP/DOP pin nets: signal / const / unconnected
proc parity_stats {cell} {
  set dip_sig 0; set dip_const 0; set dip_unc 0
  set dop_sig 0; set dop_const 0; set dop_unc 0
  set dip_nets {}
  set dop_nets {}
  foreach p [get_pins -quiet -of_objects $cell] {
    set lf [leaf $p]
    if {[string match DIP* $lf]} {
      set nn [net_of $p]
      if {$nn eq ""} { incr dip_unc } elseif {[is_const_net $nn]} { incr dip_const; lappend dip_nets "C:$lf" } else { incr dip_sig; lappend dip_nets "S:$lf=[lindex [split $nn /] end]" }
    } elseif {[string match DOP* $lf]} {
      set nn [net_of $p]
      if {$nn eq ""} { incr dop_unc } elseif {[is_const_net $nn]} { incr dop_const; lappend dop_nets "C:$lf" } else { incr dop_sig; lappend dop_nets "S:$lf=[lindex [split $nn /] end]" }
    }
  }
  return [list $dip_sig $dip_const $dip_unc $dop_sig $dop_const $dop_unc [join $dip_nets {,}] [join $dop_nets {,}]]
}

proc data_signal_count {cell prefixes} {
  set n 0
  foreach p [get_pins -quiet -of_objects $cell] {
    set lf [leaf $p]
    foreach pref $prefixes {
      if {[string match ${pref}* $lf]} {
        set nn [net_of $p]
        if {$nn ne "" && ![is_const_net $nn]} { incr n }
        break
      }
    }
  }
  return $n
}

proc unique_ctrl {cell patterns} {
  set nets {}
  foreach p [get_pins -quiet -of_objects $cell] {
    set lf [leaf $p]
    foreach pat $patterns {
      if {[string match $pat $lf]} {
        set nn [net_of $p]
        if {$nn ne "" && ![is_const_net $nn]} { dict set nets $nn 1 }
        break
      }
    }
  }
  return [lsort [dict keys $nets]]
}

open_checkpoint $dcp
set cells [lsort [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*}]]
puts "BRAM_CELL_COUNT [llength $cells]"

set fh [open $phys_tsv w]
puts $fh [join {
  hier_cell owner ref ram_mode
  READ_WIDTH_A READ_WIDTH_B WRITE_WIDTH_A WRITE_WIDTH_B
  DOA_REG DOB_REG EN_ECC_READ EN_ECC_WRITE
  clk_nets addr_a_sig_count addr_b_sig_count en_nets we_sig_count
  di_signal_count do_signal_count
  dip_signal dip_const dip_unconnected
  dop_signal dop_const dop_unconnected
  dip_nets_summary dop_nets_summary
  control_group_key
  class_hint
} \t]

array set group_members {}
array set group_meta {}

foreach c $cells {
  set owner [owner_of $c]
  set ref  [get_property REF_NAME $c]
  set mode [get_property RAM_MODE $c]
  if {$mode eq ""} { set mode "-" }
  set rwa [get_property READ_WIDTH_A $c]; if {$rwa eq ""} { set rwa 0 }
  set rwb [get_property READ_WIDTH_B $c]; if {$rwb eq ""} { set rwb 0 }
  set wwa [get_property WRITE_WIDTH_A $c]; if {$wwa eq ""} { set wwa 0 }
  set wwb [get_property WRITE_WIDTH_B $c]; if {$wwb eq ""} { set wwb 0 }
  set doa [get_property DOA_REG $c]; if {$doa eq ""} { set doa - }
  set dob [get_property DOB_REG $c]; if {$dob eq ""} { set dob - }
  set eccr [get_property EN_ECC_READ $c]; if {$eccr eq ""} { set eccr - }
  set eccw [get_property EN_ECC_WRITE $c]; if {$eccw eq ""} { set eccw - }

  set clks [unique_ctrl $c {CLKARDCLK CLKBWRCLK}]
  set ens  [unique_ctrl $c {ENARDEN ENBWREN}]
  set wes  [unique_ctrl $c {WEA* WEBWE*}]
  set addra_n [llength [unique_ctrl $c {ADDRARDADDR*}]]
  set addrb_n [llength [unique_ctrl $c {ADDRBWRADDR*}]]

  set di_n [data_signal_count $c {DIADI DIBDI}]
  set do_n [data_signal_count $c {DOADO DOBDO}]

  set ps [parity_stats $c]
  lassign $ps dip_sig dip_const dip_unc dop_sig dop_const dop_unc dip_sum dop_sum

  set clk_s [join $clks {,}]
  set en_s  [join $ens {,}]
  # shorten we to count only
  set we_n [llength $wes]

  # control group: shared non-const clock + addr signature + owner/mode/width
  # Use hierarchical clock name + addr signal count as proxy; for bit-slices same parent addr nets
  set addr_sig [join [unique_ctrl $c {ADDRARDADDR*}] {,}]
  if {[string length $addr_sig] > 120} { set addr_sig "[string range $addr_sig 0 117]..." }
  set cg_key "${owner}|${mode}|rw${rwa}|CLK={$clk_s}|ADRA_HASH=[llength [unique_ctrl $c {ADDRARDADDR*}]]"

  # classification hint from widths + parity connectivity
  set class UNKNOWN
  if {$mode eq "SDP" && ($rwa == 72 || $wwb == 72)} {
    if {$dip_sig >= 8 && $dop_sig >= 8} {
      set class FULL_X72_PAYLOAD
    } elseif {$dip_sig > 0 || $dop_sig > 0} {
      set class PARITY_USED
    } else {
      set class UNKNOWN
    }
  } elseif {$rwa == 9 || $wwa == 9} {
    if {$dip_sig > 0 || $dop_sig > 0} {
      set class PARITY_USED
    } else {
      set class UNKNOWN
    }
  } elseif {$rwa == 1 && $wwa == 1} {
    if {$dip_sig == 0 && $dop_sig == 0} {
      set class BIT_SLICED_PORT_BOUND
    } else {
      set class UNKNOWN
    }
  }

  puts $fh [join [list \
    $c $owner $ref $mode \
    $rwa $rwb $wwa $wwb \
    $doa $dob $eccr $eccw \
    $clk_s $addra_n $addrb_n $en_s $we_n \
    $di_n $do_n \
    $dip_sig $dip_const $dip_unc \
    $dop_sig $dop_const $dop_unc \
    $dip_sum $dop_sum \
    $cg_key $class \
  ] \t]

  if {![info exists group_members($cg_key)]} {
    set group_members($cg_key) {}
    set group_meta($cg_key) [list $owner $mode $rwa]
  }
  lappend group_members($cg_key) $c
}
close $fh

set gh [open $group_tsv w]
puts $gh "control_group_key\towner\tmode\trw_a\tmember_count\tmembers"
foreach k [lsort [array names group_members]] {
  set meta $group_meta($k)
  set mems $group_members($k)
  puts $gh [join [list $k [lindex $meta 0] [lindex $meta 1] [lindex $meta 2] [llength $mems] [join $mems {,}]] \t]
}
close $gh

# ECC / width aggregate
puts "WROTE $phys_tsv"
puts "WROTE $group_tsv"
puts "PHYS_AUDIT_DONE"
