`timescale 1ns/1ps
// 256 x 8 INT16 (128-bit row). GEMV uses lane 0.
module tile_activation (
    input  logic         clk,
    input  logic         wr_en,
    input  logic [7:0]   wr_k,
    input  logic [127:0] wr_data,
    input  logic [7:0]   rd_k,
    output logic [127:0] rd_data
);
    (* ram_style = "block" *) logic [127:0] mem [0:255];
    always_ff @(posedge clk) begin
        if (wr_en) mem[wr_k] <= wr_data;
        rd_data <= mem[rd_k];
    end
endmodule
