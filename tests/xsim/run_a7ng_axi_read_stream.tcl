# run_a7ng_axi_read_stream.tcl — fast protocol unit (engineering only)
set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir  [file join $root results A7-NATIVE-GRAPH DDR-CUE-SOA-00 00R]
file mkdir $outdir
cd $xsimdir
if {[file exists xsim.dir]} { catch {file delete -force xsim.dir} }

set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
foreach tool {xvlog_bin xelab_bin xsim_bin} {
  if {![file exists [set $tool]]} { set $tool [file tail [set $tool]] }
}

set prj [file join $outdir axi_read_stream_unit.prj]
set fh [open $prj w]
puts $fh "sv work \"[file join $root rtl/native_graph/memory/a7ng_soa_plane_engine.sv]\""
puts $fh "sv work \"[file join $root rtl/native_graph/memory/a7ng_soa_plane_fetch.sv]\""
puts $fh "sv work \"[file join $root rtl/native_graph/memory/a7ng_axi_read_stream.sv]\""
puts $fh "sv work \"[file join $xsimdir tb_a7ng_axi_read_stream.sv]\""
puts $fh "verilog work \"C:/2026.1/Vivado/data/verilog/src/glbl.v\""
close $fh

set xvlog_log [file join $outdir xvlog_axi_read_stream_unit.log]
exec $xvlog_bin -prj $prj > $xvlog_log 2>@1
set xelab_log [file join $outdir xelab_axi_read_stream_unit.log]
exec $xelab_bin -mt off -O0 tb_a7ng_axi_read_stream glbl -s tb_axi_read_stream_sim \
    -timescale 1ns/1ps > $xelab_log 2>@1
set xsim_log [file join $outdir xsim_axi_read_stream_unit.log]
exec $xsim_bin tb_axi_read_stream_sim -R -log $xsim_log
set log [read [open $xsim_log r]]
puts $log
if {[string match *A7NG_AXI_READ_STREAM_UNIT_PASS* $log]} { exit 0 }
exit 1
