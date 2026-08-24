`timescale 1ns/1ps
module psum_bank (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               wr_all,
    input  logic signed [31:0] wr_vec [0:127],
    input  logic [6:0]         rd_idx,
    output logic signed [31:0] rd_val
);
    logic signed [31:0] mem [0:127];
    integer i;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 128; i = i + 1) mem[i] <= 32'sd0;
        end else if (wr_all) begin
            for (i = 0; i < 128; i = i + 1) mem[i] <= wr_vec[i];
        end
    end
    assign rd_val = mem[rd_idx];
endmodule
