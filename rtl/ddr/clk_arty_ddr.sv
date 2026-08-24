`timescale 1ns/1ps
// 100 MHz -> 166.667 MHz sys_clk_i and 200 MHz clk_ref_i for Digilent MIG (No Buffer).
module clk_arty_ddr (
    input  logic clk100,
    input  logic rst,
    output logic clk_166,
    output logic clk_200,
    output logic locked
);
`ifdef SYNTHESIS
    wire clkfb_raw, clkfb_buf, c166_raw, c200_raw, mmcm_locked;
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.000),
        .CLKOUT0_DIVIDE_F(6.000),
        .CLKOUT1_DIVIDE(5),
        .STARTUP_WAIT("FALSE")
    ) mmcm_i (
        .CLKIN1(clk100),
        .CLKFBIN(clkfb_buf),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb_raw),
        .CLKOUT0(c166_raw),
        .CLKOUT1(c200_raw),
        .LOCKED(mmcm_locked)
    );
    BUFG fb_i (.I(clkfb_raw), .O(clkfb_buf));
    BUFG u166 (.I(c166_raw), .O(clk_166));
    BUFG u200 (.I(c200_raw), .O(clk_200));
    assign locked = mmcm_locked;
`else
    assign clk_166 = clk100;
    assign clk_200 = clk100;
    assign locked = 1'b1;
`endif
endmodule
