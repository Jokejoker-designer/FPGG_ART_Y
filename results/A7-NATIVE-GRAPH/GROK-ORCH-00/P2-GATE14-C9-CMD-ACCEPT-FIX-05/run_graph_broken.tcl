# Diagnostic: C9-04 one-cycle valid. Expect GRAPH_ACCEPT != 20. PROGRAM=NO.
set bag [file normalize [file dirname [info script]]]
set ::env(C9_BROKEN_HS) 1
source [file join $bag run_graph_only.tcl]
