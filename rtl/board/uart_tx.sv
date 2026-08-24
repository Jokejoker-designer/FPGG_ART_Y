`timescale 1ns/1ps
module uart_tx #(
    parameter int CLK_HZ = 8000000,
    parameter int BAUD = 115200
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [7:0] data,
    output logic tx,
    output logic busy
);
    localparam int CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;
    localparam int CW = $clog2(CLKS_PER_BIT+1);
    logic [CW-1:0] clk_count;
    logic [3:0] bit_index;
    logic [7:0] data_reg;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx <= 1'b1;
            busy <= 1'b0;
            clk_count <= '0;
            bit_index <= '0;
            data_reg <= '0;
        end else if (!busy) begin
            tx <= 1'b1;
            clk_count <= '0;
            bit_index <= '0;
            if (start) begin
                data_reg <= data;
                busy <= 1'b1;
                tx <= 1'b0; // start bit
            end
        end else if (clk_count == CLKS_PER_BIT-1) begin
            clk_count <= '0;
            if (bit_index < 8) begin
                tx <= data_reg[bit_index];
                bit_index <= bit_index + 1'b1;
            end else if (bit_index == 8) begin
                tx <= 1'b1; // stop bit
                bit_index <= bit_index + 1'b1;
            end else begin
                busy <= 1'b0;
                tx <= 1'b1;
            end
        end else begin
            clk_count <= clk_count + 1'b1;
        end
    end
endmodule
