`timescale 1ns/1ps
module argmax32 (
    input  logic clk,
    input  logic rst_n,
    input  logic init,
    input  logic step,
    input  logic signed [31:0] z,
    input  logic [4:0] idx,
    output logic [4:0] pred,
    output logic signed [31:0] best
);
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pred <= 5'd0;
            best <= 32'sd0;
        end else if (init) begin
            pred <= idx;
            best <= z;
        end else if (step && (z > best)) begin
            pred <= idx;
            best <= z;
        end
    end
endmodule
