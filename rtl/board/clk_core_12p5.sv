`timescale 1ns/1ps
// 100 MHz -> 12.5 MHz (80 ns) MMCM core clock for E2R native_v1 existence lane.
module clk_core_12p5 (
    input  logic clk100,
    input  logic rst,
    output logic clk_core,
    output logic locked
);
`ifdef SYNTHESIS
    wire clkfb_raw, clkfb_buf, core_raw, mmcm_locked;
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.000),
        .CLKOUT0_DIVIDE_F(80.000),
        .STARTUP_WAIT("FALSE")
    ) mmcm_i (
        .CLKIN1(clk100),
        .CLKFBIN(clkfb_buf),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb_raw),
        .CLKOUT0(core_raw),
        .LOCKED(mmcm_locked)
    );
    BUFG fb_i (.I(clkfb_raw), .O(clkfb_buf));
    BUFG core_i (.I(core_raw), .O(clk_core));
    assign locked = mmcm_locked;
`else
    assign clk_core = clk100;
    assign locked   = 1'b1;
`endif
endmodule
