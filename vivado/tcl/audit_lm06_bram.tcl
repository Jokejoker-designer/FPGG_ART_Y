# LM06-Q0 BRAM ownership audit.
#
# Question this answers: LM-06 keeps its weights in DDR, yet post-route it holds
# 132 of 135 BRAM tiles. What are those tiles actually for? If most of them are
# activation/scratch, then dropping weights from 8-bit to 2-bit frees almost no
# BRAM and only helps DDR bandwidth. If most of them stage weight tiles, low-bit
# weights attack the 180%-BRAM integration problem directly.
#
# Read-only. Opens an archived checkpoint, writes a report, changes nothing.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set dcp        [file join $root_dir build/out/a7lm06_post_route.dcp]
set out        [file join $root_dir results/A7-NATIVE-V1/LM06_Q0_BRAM/bram_cells.tsv]

if {![file exists $dcp]} {
    puts stderr "ERROR: missing $dcp"
    exit 2
}
file mkdir [file dirname $out]

open_checkpoint $dcp

set cells [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*}]
puts "BRAM_CELL_COUNT [llength $cells]"

set fh [open $out w]
puts $fh "cell\tref\tram_mode\trw_a\trw_b\tww_a\tww_b\tl1\tl2\tl3"
foreach c $cells {
    set ref  [get_property REF_NAME  $c]
    set mode [get_property RAM_MODE  $c]
    if {$mode eq ""} { set mode "-" }
    foreach {p v} {READ_WIDTH_A rwa READ_WIDTH_B rwb WRITE_WIDTH_A wwa WRITE_WIDTH_B wwb} {
        set val [get_property $p $c]
        if {$val eq ""} { set val 0 }
        set $v $val
    }
    set parts [split $c /]
    set l1 [lindex $parts 0]
    set l2 [expr {[llength $parts] > 1 ? [lindex $parts 1] : "-"}]
    set l3 [expr {[llength $parts] > 2 ? [lindex $parts 2] : "-"}]
    puts $fh "$c\t$ref\t$mode\t$rwa\t$rwb\t$wwa\t$wwb\t$l1\t$l2\t$l3"
}
close $fh
puts "WROTE $out"

# aggregate by first two hierarchy levels so ownership is visible immediately
array set agg {}
foreach c $cells {
    set parts [split $c /]
    set key [join [lrange $parts 0 1] /]
    if {[llength $parts] < 2} { set key [lindex $parts 0] }
    if {[info exists agg($key)]} { incr agg($key) } else { set agg($key) 1 }
}
puts "=== BRAM BY HIERARCHY (level 1/2) ==="
foreach k [lsort [array names agg]] {
    puts [format "%-70s %4d" $k $agg($k)]
}
puts "AUDIT_DONE"
