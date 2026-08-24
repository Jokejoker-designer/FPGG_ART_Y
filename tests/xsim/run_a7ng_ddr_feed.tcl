set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
cd $xsimdir
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}
set src [list \
    [file join $root rtl/native_graph/memory a7ng_mem_schema_v1.sv] \
    [file join $root rtl/native_graph/memory a7ng_ddr_feed_lat_ddr.sv] \
    [file join $root rtl/native_graph/memory a7ng_ddr_feed_pp.sv] \
    [file join $root rtl/native_graph/memory a7ng_ddr_feed_top.sv] \
    [file join $xsimdir tb_a7ng_ddr_feed.sv]]
if {[catch {exec $xvlog_bin -sv {*}$src} vlog_out]} { puts $vlog_out; puts XVLOG_FAIL; exit 2 }
puts $vlog_out
if {[catch {exec $xelab_bin tb_a7ng_ddr_feed -s tb_a7ng_ddr_feed -timescale 1ns/1ps} elab_out]} { puts $elab_out; puts XELAB_FAIL; exit 3 }
puts $elab_out
if {[catch {exec $xsim_bin tb_a7ng_ddr_feed -runall} sim_out]} { puts $sim_out; puts XSIM_FAIL; exit 4 }
puts $sim_out
if {![string match "*A7NG_DDR_FEED_XSIM_PASS*" $sim_out]} { puts A7NG_DDR_FEED_NO_PASS; exit 5 }
puts A7NG_DDR_FEED_XSIM_OK
