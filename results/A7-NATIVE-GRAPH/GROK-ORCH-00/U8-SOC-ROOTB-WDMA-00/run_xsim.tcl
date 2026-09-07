set bag  [file normalize [file dirname [info script]]]
set root [file normalize [file join $bag ../../../..]]
set xvlog_bin [file normalize {C:/2026.1/Vivado/bin/xvlog.bat}]
set xelab_bin [file normalize {C:/2026.1/Vivado/bin/xelab.bat}]
set xsim_bin  [file normalize {C:/2026.1/Vivado/bin/xsim.bat}]
set glbl      [file normalize {C:/2026.1/Vivado/data/verilog/src/glbl.v}]
set env(XILINXD_LICENSE_FILE) {D:\Xilinx\licenses\vivado_basic.lic}
set work [file join $bag xsim_work]
file mkdir $work
cd $work
set src [list \
  [file join $root rtl/native_graph/pkg/a7ng_pkg.sv] \
  [file join $root rtl/native_graph/learn/a7ng_learned_prior_store.sv] \
  [file join $root rtl/native_graph/learn/a7ng_persist_axi_bridge.sv] \
  [file join $root rtl/board/a7ng_wdma_cdc.sv] \
  [file join $root rtl/ddr/ddr_tile_dma.sv] \
  [file join $bag tb_u8_persist_axi_mem.sv] \
  [file join $bag tb_u8_soc_rootb_wdma.sv] \
]
set xvlog_log [file join $bag xvlog.log]
if {[catch {exec $xvlog_bin -sv {*}$src > $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U8_SOC_ROOTB_WDMA_XVLOG_FAIL
  exit 2
}
if {[catch {exec $xvlog_bin $glbl >> $xvlog_log 2>@1}]} {
  puts [read [open $xvlog_log r]]
  puts U8_SOC_ROOTB_WDMA_GLBL_XVLOG_FAIL
  exit 2
}
set xelab_log [file join $bag xelab.log]
if {[catch {exec $xelab_bin -mt off -O0 tb_u8_soc_rootb_wdma glbl -s u8wdma -L xpm -timescale 1ns/1ps > $xelab_log 2>@1}]} {
  puts [read [open $xelab_log r]]
  puts U8_SOC_ROOTB_WDMA_XELAB_FAIL
  exit 3
}
set xsim_log [file join $bag xsim.log]
catch {exec $xsim_bin u8wdma -R -log $xsim_log}
set body [read [open $xsim_log r]]
puts $body
if {[string match *FIRST_DIVERGENCE* $body]} {
  puts U8_SOC_ROOTB_WDMA_FIRST_DIVERGENCE
  exit 6
}
if {![string match *U8_SOC_ROOTB_WDMA_PASS* $body]} {
  puts U8_SOC_ROOTB_WDMA_NOT_PASS
  exit 5
}
puts U8_SOC_ROOTB_WDMA_XSIM_OK
exit 0
