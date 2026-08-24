`timescale 1ns/1ps
// Sim-only 1M x INT8 (802816 used). Silicon uses weight_tile803k banks.
module weight_bram803k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [19:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [19:0]        addr_b,
    output logic signed [7:0]  rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [7:0] mem [0:1048575];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
