`timescale 1ns/1ps
// UG901 TDP INT8, READ_FIRST. Same lock as weight_bram100k / weight_bram25k.
module weight_bram_tdp8 #(
    parameter int DEPTH = 65536
) (
    input  logic                       clk,
    input  logic                       we_a,
    input  logic [$clog2(DEPTH)-1:0]   addr_a,
    input  logic signed [7:0]          wdata_a,
    output logic signed [7:0]          rdata_a,
    input  logic [$clog2(DEPTH)-1:0]   addr_b,
    output logic signed [7:0]          rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [7:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
