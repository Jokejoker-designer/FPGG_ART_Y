# Cheap OOC synth for frontier shootout arms — LUT/FF only (M7). M8 WNS = NA.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set outdir [file join $root results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT]
file mkdir $outdir
set build [file join $outdir vivado_ooc]
file mkdir $build
set part xc7a100tcsg324-1

proc synth_one {root build outdir part name top src extras} {
  set proj [file join $build $name]
  file mkdir $proj
  create_project -force $name $proj -part $part
  set f [add_files -norecurse $src]
  set_property file_type SystemVerilog $f
  set_property top $top [current_fileset]
  if {$extras ne ""} {
    set_property generic $extras [get_filesets sources_1]
  }
  synth_design -top $top -part $part -mode out_of_context
  report_utilization -file [file join $outdir "util_${name}.rpt"]
  set util [report_utilization -return_string]
  set lut_v NA
  set ff_v NA
  foreach line [split $util "\n"] {
    if {[regexp {CLB LUTs[^|]*\|\s+([0-9]+)} $line -> v]} { set lut_v $v }
    if {[regexp {Slice LUTs[^|]*\|\s+([0-9]+)} $line -> v]} { set lut_v $v }
    if {[regexp {CLB Registers[^|]*\|\s+([0-9]+)} $line -> v]} { set ff_v $v }
    if {[regexp {Slice Registers[^|]*\|\s+([0-9]+)} $line -> v]} { set ff_v $v }
  }
  puts "OOC_ROW $name $top LUT=$lut_v FF=$ff_v"
  close_design
  close_project
  return [list $lut_v $ff_v]
}

set csv [open [file join $outdir OOC_UTIL.csv] w]
puts $csv "arm,module,LUT,FF"

set r [synth_one $root $build $outdir $part A_bucket a7ng_frontier_buckets \
  [file join $root rtl/native_graph/frontier/a7ng_frontier_buckets.sv] {NBINS=16 DEPTH=4}]
puts $csv "A_bucket,a7ng_frontier_buckets,[lindex $r 0],[lindex $r 1]"

set r [synth_one $root $build $outdir $part B_systolic a7ng_frontier_systolic_pq \
  [file join $root rtl/native_graph/frontier/a7ng_frontier_systolic_pq.sv] ""]
puts $csv "B_systolic,a7ng_frontier_systolic_pq,[lindex $r 0],[lindex $r 1]"

set r [synth_one $root $build $outdir $part C_twolevel a7ng_frontier_twolevel \
  [file join $root rtl/native_graph/frontier/a7ng_frontier_twolevel.sv] ""]
puts $csv "C_twolevel,a7ng_frontier_twolevel,[lindex $r 0],[lindex $r 1]"

close $csv
puts "FRONTIER_SHOOTOUT_OOC_DONE"
exit 0
