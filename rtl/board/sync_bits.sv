`timescale 1ns/1ps
module sync_bits #(
    parameter int WIDTH = 1
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] async_in,
    output logic [WIDTH-1:0] sync_out
);
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] meta;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            meta <= '0;
            sync_out <= '0;
        end else begin
            meta <= async_in;
            sync_out <= meta;
        end
    end
endmodule
