`timescale 1ns/1ps
module mac64 (
    input  logic clk,
    input  logic rst_n,
    input  logic clr,
    input  logic en,
    input  logic signed [31:0] a,
    input  logic signed [31:0] b,
    output logic signed [63:0] acc
);
    always_ff @(posedge clk) begin
        if (!rst_n || clr)
            acc <= 64'sd0;
        else if (en)
            acc <= acc + 64'(a) * 64'(b);
    end
endmodule
