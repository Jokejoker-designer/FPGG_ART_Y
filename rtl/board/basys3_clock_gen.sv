`timescale 1ns/1ps
module basys3_clock_gen (
    input  logic clk100,
    input  logic rst,
    output logic clk_core,
    output logic locked
);
`ifdef SYNTHESIS
    wire clkfb_raw;
    wire clkfb_buf;
    wire clk_core_raw;
    wire mmcm_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.000),
        .CLKOUT0_DIVIDE_F(125.000),
        .STARTUP_WAIT("FALSE")
    ) mmcm_i (
        .CLKIN1(clk100),
        .CLKFBIN(clkfb_buf),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb_raw),
        .CLKOUT0(clk_core_raw),
        .LOCKED(mmcm_locked)
    );

    BUFG fb_bufg_i (.I(clkfb_raw), .O(clkfb_buf));
    BUFG core_bufg_i (.I(clk_core_raw), .O(clk_core));
    always_comb locked = mmcm_locked;
`else
    logic [2:0] div_counter = 3'd0;
    logic [3:0] lock_counter = 4'd0;
    always_ff @(posedge clk100) begin
        if (rst) begin
            div_counter <= 3'd0;
            lock_counter <= 4'd0;
            locked <= 1'b0;
        end else begin
            div_counter <= div_counter + 1'b1;
            if (!locked) begin
                if (lock_counter == 4'd10) locked <= 1'b1;
                else lock_counter <= lock_counter + 1'b1;
            end
        end
    end
    always_comb clk_core = div_counter[2];
`endif
endmodule
