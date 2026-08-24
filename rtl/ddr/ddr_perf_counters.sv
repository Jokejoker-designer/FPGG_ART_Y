`timescale 1ns/1ps
module ddr_perf_counters (
    input  logic clk,
    input  logic rst_n,
    input  logic clr,
    input  logic wr_beat,
    input  logic rd_beat,
    input  logic err_inc,
    output logic [63:0] wr_bytes,
    output logic [63:0] rd_bytes,
    output logic [63:0] wr_cycles,
    output logic [63:0] rd_cycles,
    output logic [31:0] err_count,
    input  logic wr_active,
    input  logic rd_active
);
    always_ff @(posedge clk) begin
        if (!rst_n || clr) begin
            wr_bytes <= 64'd0;
            rd_bytes <= 64'd0;
            wr_cycles <= 64'd0;
            rd_cycles <= 64'd0;
            err_count <= 32'd0;
        end else begin
            if (wr_beat) wr_bytes <= wr_bytes + 64'd16;
            if (rd_beat) rd_bytes <= rd_bytes + 64'd16;
            if (wr_active) wr_cycles <= wr_cycles + 64'd1;
            if (rd_active) rd_cycles <= rd_cycles + 64'd1;
            if (err_inc) err_count <= err_count + 32'd1;
        end
    end
endmodule
