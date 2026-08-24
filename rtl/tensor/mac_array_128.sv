`timescale 1ns/1ps
module mac_array_128 (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clr,
    input  logic               en,
    input  logic signed [15:0] a [0:127],
    input  logic signed [7:0]  b [0:127],
    output logic signed [47:0] acc [0:127]
);
    genvar i;
    generate
        for (i = 0; i < 128; i++) begin : G
            mac_lane u (
                .clk(clk), .rst_n(rst_n), .clr(clr), .en(en),
                .a(a[i]), .b(b[i]), .acc(acc[i])
            );
        end
    endgenerate
endmodule
