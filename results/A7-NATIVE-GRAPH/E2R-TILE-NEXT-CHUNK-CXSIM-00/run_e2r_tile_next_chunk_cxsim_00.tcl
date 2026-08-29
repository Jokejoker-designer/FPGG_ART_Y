set root [file normalize [file join [file dirname [info script]] ../..]]
set xsimdir [file join $root tests xsim]
set outdir [file join $root results A7-NATIVE-GRAPH E2R-TILE-NEXT-CHUNK-CXSIM-00]
file mkdir $outdir
cd $outdir

set src [list \
  [file join $root rtl/lm a7lm06_pkg.sv] \
  [file join $root rtl/lm weight_bram_tdp8.sv] \
  [file join $root rtl/lm weight_tile803k.sv] \
  [file join $xsimdir tb_e2r_tile_next_chunk_cxsim_00.sv]]

if {[catch {exec xvlog -sv {*}$src} vlog_out]} {
  puts $vlog_out
  puts "XVLOG_FAIL"
  exit 2
}
puts $vlog_out

set glbl C:/2026.1/Vivado/data/verilog/src/glbl.v
if {[catch {exec xvlog $glbl} glbl_out]} {
  puts $glbl_out
  puts "XVLOG_GLBL_FAIL"
  exit 2
}

if {[catch {exec xelab tb_e2r_tile_next_chunk_cxsim_00 glbl -s tb_e2r_tile_next_chunk_cxsim_00_sim -timescale 1ns/1ps} elab_out]} {
  puts $elab_out
  puts "XELAB_FAIL"
  exit 3
}
puts $elab_out

set logfile [file join $outdir xsim.log]
if {[catch {exec xsim tb_e2r_tile_next_chunk_cxsim_00_sim -runall} sim_out]} {
  set f [open $logfile w]
  puts $f $sim_out
  close $f
  puts $sim_out
  puts "XSIM_FAIL"
  exit 4
}
set f [open $logfile w]
puts $f $sim_out
close $f
puts $sim_out

if {[string match "*E2R_TILE_NEXT_CHUNK_CXSIM_00_XSIM_PASS*" $sim_out]} {
  puts "E2R_TILE_NEXT_CHUNK_CXSIM_00_OK"
  exit 0
}
puts "E2R_TILE_NEXT_CHUNK_CXSIM_00_NO_PASS"
exit 5
