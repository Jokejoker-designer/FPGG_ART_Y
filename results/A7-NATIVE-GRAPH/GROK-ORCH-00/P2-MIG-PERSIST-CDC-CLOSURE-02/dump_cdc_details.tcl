# P2-MIG-PERSIST-CDC-CLOSURE-02 — detailed/verbose CDC from post-route DCPs.
# PROGRAM=NO. No bitstream. No board.
set bag [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
if {![string match "*arty-a7-online-lm-grok-orch-00" $root]} {
  puts stderr "REFUSE: not grok-orch-00 root=$root"
  exit 3
}

proc dump_one {tag dcp bag} {
  if {![file exists $dcp]} {
    puts stderr "MISSING_DCP $tag $dcp"
    return 1
  }
  puts "=== OPEN $tag $dcp ==="
  close_design -quiet
  open_checkpoint $dcp
  set det [file join $bag "report_cdc_details_${tag}.rpt"]
  report_cdc -details -file $det
  set verb [file join $bag "report_cdc_verbose_${tag}.rpt"]
  if {[catch {report_cdc -details -verbose -file $verb} e]} {
    puts "WARN verbose $tag $e"
  }
  set sum [file join $bag "report_cdc_summary_${tag}.rpt"]
  report_cdc -file $sum

  set lf [open [file join $bag "cdc_unsafe_pins_${tag}.txt"] w]
  puts $lf "TAG=$tag"
  puts $lf "DCP=$dcp"
  foreach pair {
    {core_clk clk_pll_i}
    {clk_pll_i core_clk}
    {c166_raw clk_pll_i}
  } {
    set src [lindex $pair 0]
    set dst [lindex $pair 1]
    set cs [get_clocks -quiet $src]
    set cd [get_clocks -quiet $dst]
    puts $lf ""
    puts $lf "PAIR $src -> $dst clocks=[llength $cs]/[llength $cd]"
    if {[llength $cs] == 0 || [llength $cd] == 0} { continue }
    # Ungrouped timing paths still exist even under async clock groups.
    set paths [get_timing_paths -quiet -from $cs -to $cd -nworst 200 -max_paths 200 -setup -ignore_clock_groups]
    puts $lf "timing_paths_ignore_clock_groups=[llength $paths]"
    set i 0
    foreach p $paths {
      incr i
      if {$i > 80} { break }
      set sp [get_property STARTPOINT_PIN $p]
      set ep [get_property ENDPOINT_PIN $p]
      set sl [get_property SLACK $p]
      set lv [get_property LOGIC_LEVELS $p]
      set nets ""
      catch { set nets [get_property NETS $p] }
      puts $lf "PATH$i slack=$sl levels=$lv"
      puts $lf "  START $sp"
      puts $lf "  END   $ep"
      set pers 0
      if {[string match "*persist*" [string tolower "$sp $ep"]] ||
          [string match "*u_persist*" "$sp $ep"] ||
          [string match "*c_tog*" "$sp $ep"] ||
          [string match "*c_done*" "$sp $ep"] ||
          [string match "*c_kind*" "$sp $ep"] ||
          [string match "*c_slot*" "$sp $ep"] ||
          [string match "*c_wdata*" "$sp $ep"] ||
          [string match "*c_rdata*" "$sp $ep"] ||
          [string match "*c_ok*" "$sp $ep"]} {
        set pers 1
      }
      puts $lf "  PERSIST_NAME=$pers"
    }
  }
  # Hierarchy cells matching persist
  set pc [get_cells -quiet -hierarchical -filter {NAME =~ *persist*}]
  puts $lf ""
  puts $lf "PERSIST_CELLS count=[llength $pc]"
  foreach c [lsort $pc] {
    if {[string match "*u_persist*" $c] || [string match "*persist_axi*" $c] || [string match "*persist_grant*" $c]} {
      puts $lf "CELL $c ref=[get_property REF_NAME $c]"
    }
  }
  close $lf
  puts "WROTE $det"
  puts "WROTE $sum"
  return 0
}

set persist_dcp [file join $root results A7-NATIVE-GRAPH GROK-ORCH-00 P2-G1G5-FULLCHIP-MIG-PERSIST-01 e2r_post_route.dcp]
set cofit_dcp   [file join $root results A7-NATIVE-GRAPH GROK-ORCH-00 P2-G1G5-FULLCHIP-COFIT-00 e2r_post_route.dcp]

dump_one persist $persist_dcp $bag
dump_one cofit   $cofit_dcp   $bag
puts "CDC_DUMP_DONE PROGRAM=NO"
exit 0
