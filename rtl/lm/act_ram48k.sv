`timescale 1ns/1ps
// Dense 48K x INT32 act map for LM-05 silicon.
// Live set is 8 tensors x 64 tok x 96 dim = 49152 (ly reused across layers).
module act_ram48k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [15:0]        addr_a,
    input  logic signed [31:0] wdata_a,
    output logic signed [31:0] rdata_a,
    input  logic [15:0]        addr_b,
    output logic signed [31:0] rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [31:0] mem [0:49151];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
