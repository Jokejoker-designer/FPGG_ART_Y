`timescale 1ns/1ps
// 1024 x 32 dual-read activation scratch. addr = {tensor[2:0], tok[2:0], dim[3:0]}.
module act_ram_tdp32 (
    input  logic clk,
    input  logic we_a,
    input  logic [9:0] addr_a,
    input  logic signed [31:0] wdata_a,
    output logic signed [31:0] rdata_a,
    input  logic [9:0] addr_b,
    output logic signed [31:0] rdata_b
);
    (* ram_style = "block" *) logic signed [31:0] mem [0:1023];
    always_ff @(posedge clk) begin
        if (we_a)
            mem[addr_a] <= wdata_a;
        rdata_a <= mem[addr_a];
        rdata_b <= mem[addr_b];
    end
endmodule
