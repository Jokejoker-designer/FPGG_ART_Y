`timescale 1ns/1ps
// INT8 weight store, true dual-port. 3200 used words.
module weight_bram4096 (
    input  logic clk,
    input  logic we_a,
    input  logic [11:0] addr_a,
    input  logic signed [7:0] wdata_a,
    output logic signed [7:0] rdata_a,
    input  logic [11:0] addr_b,
    output logic signed [7:0] rdata_b
);
    (* ram_style = "block" *) logic signed [7:0] mem [0:4095];
    always_ff @(posedge clk) begin
        if (we_a)
            mem[addr_a] <= wdata_a;
        rdata_a <= mem[addr_a];
        rdata_b <= mem[addr_b];
    end
endmodule
