`timescale 1ns/1ps
// 131072 x INT8 working scratch (100352 used). Persistent image is DDR.
// Same UG901 READ_FIRST lock as weight_bram25k.
module weight_bram100k (
    input  logic               clk,
    input  logic               we_a,
    input  logic [16:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [16:0]        addr_b,
    output logic signed [7:0]  rdata_b
);
    (* ram_style = "block", rw_addr_collision = "yes" *)
    logic signed [7:0] mem [0:131071];

    always_ff @(posedge clk) begin
        rdata_a <= mem[addr_a];
        if (we_a)
            mem[addr_a] <= wdata_a;
    end

    always_ff @(posedge clk) begin
        rdata_b <= mem[addr_b];
    end
endmodule
