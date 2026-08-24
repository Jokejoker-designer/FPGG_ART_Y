`timescale 1ns/1ps
// 1M x INT32 sim act map so {aa,ah,ay} 20-bit regions do not wrap.
module act_ram1m (
    input  logic               clk,
    input  logic               we_a,
    input  logic [19:0]        addr_a,
    input  logic signed [31:0] wdata_a,
    output logic signed [31:0] rdata_a,
    input  logic [19:0]        addr_b,
    output logic signed [31:0] rdata_b
);
    logic signed [31:0] mem [0:1048575];
    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a) mem[addr_a] <= wdata_a;
    end
    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
