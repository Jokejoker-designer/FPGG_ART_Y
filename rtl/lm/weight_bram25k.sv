`timescale 1ns/1ps
// 32768 x INT8. 25088 words used. Dual-port block RAM.
// Locked READ_FIRST, registered output, latency = 1 clk on both ports.
// UG901 READ_FIRST: sample mem[addr] into rdata, then apply the write.
// RTL NBA of "write then rdata<=mem[addr]" is READ_FIRST in sim but Vivado
// may infer WRITE_FIRST/NO_CHANGE. Full-step RMW uses wrd as the pre-write
// value, so the mode must be explicit and identical in RTL and netlist.
module weight_bram25k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [14:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [14:0]        addr_b,
    output logic signed [7:0]  rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [7:0] mem [0:32767];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
