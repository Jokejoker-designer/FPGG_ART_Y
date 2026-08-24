`timescale 1ns/1ps
// 524288 x INT32 partitioned act map for 4-layer xsim only.
module act_ram512k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [19:0]        addr_a,
    input  logic signed [31:0] wdata_a,
    output logic signed [31:0] rdata_a,
    input  logic [19:0]        addr_b,
    output logic signed [31:0] rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [31:0] mem [0:524287];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
