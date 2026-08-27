# E2R core_clk constraints — sourced from build/route Tcl (not raw XDC; no if in XDC)
proc e2r_apply_core_clk_constraints {} {
  set core_in [get_pins -quiet u_core_pll/mmcm_i/CLKIN1]
  set core_bufg [get_pins -quiet u_core_pll/core_i/O]
  if {[llength $core_in] > 0 && [llength $core_bufg] > 0} {
    if {[llength [get_clocks -quiet core_clk]] == 0} {
      create_generated_clock -name core_clk -source $core_in \
        -multiply_by 10 -divide_by 80 $core_bufg
    }
  }

  set core_c [get_clocks -quiet core_clk]
  if {[llength $core_c] == 0} { set core_c [get_clocks -quiet core_raw] }
  set ui_c [get_clocks -quiet clk_pll_i]
  if {[llength $core_c] > 0 && [llength $ui_c] > 0} {
    set_clock_groups -asynchronous -group $core_c -group $ui_c
  }
}
