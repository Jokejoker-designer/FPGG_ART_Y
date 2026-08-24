# Open 00S / 00B / 00G route DCPs and dump hierarchical + RAM utilization.
set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ../..]]
set out_dir    [file join $root_dir build out]
set res_dir    [file join $root_dir results A7-EAM-00]
file mkdir $res_dir

foreach {tag dcp} {
    00s a7eam00s_post_route.dcp
    00b a7eam00b_post_route.dcp
    00g a7eam00g_post_route.dcp
} {
    set p [file join $out_dir $dcp]
    if {![file exists $p]} {
        puts "SKIP $tag missing $p"
        continue
    }
    puts "=== OPEN $tag $p ==="
    open_checkpoint $p
    report_utilization -hierarchical -file [file join $res_dir ram_${tag}_util_hier.rpt]
    if {[catch {report_ram_utilization -file [file join $res_dir ram_${tag}_ramutil.rpt] -append} err]} {
        puts "WARN report_ram_utilization $tag: $err"
        if {[catch {report_ram_utilization -file [file join $res_dir ram_${tag}_ramutil.rpt]} err2]} {
            puts "WARN retry $err2"
        }
    }
    set rams [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ BMEM.BRAM.* || REF_NAME =~ RAMB*}]
    puts "RAM_COUNT $tag [llength $rams]"
    foreach c [lsort $rams] {
        set ref [get_property REF_NAME $c]
        set loc [get_property LOC $c]
        puts "RAM $tag $ref $loc $c"
    }
    close_design
}
puts "A7_EAM_RAM_REPORT_DONE"
