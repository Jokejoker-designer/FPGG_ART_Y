`timescale 1ns/1ps
// Snapshot of all principal INT8 weights (3200 words).
module ckpt_bram3200 (
    input  logic clk,
    input  logic we,
    input  logic [11:0] addr,
    input  logic signed [7:0] wdata,
    output logic signed [7:0] rdata
);
    (* ram_style = "block" *) logic signed [7:0] mem [0:3199];
    always_ff @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        rdata <= mem[addr];
    end
endmodule
