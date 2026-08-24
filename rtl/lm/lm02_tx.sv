`timescale 1ns/1ps
module lm02_tx #(
    parameter int CLK_HZ = 8000000,
    parameter int BAUD = 115200
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [7:0] frame [0:14],
    output logic tx,
    output logic busy
);
    logic uart_start, uart_busy;
    logic [7:0] uart_data;
    logic [3:0] idx;
    logic sending;

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(uart_start), .data(uart_data),
        .tx(tx), .busy(uart_busy)
    );

    assign busy = sending;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sending <= 1'b0;
            idx <= 4'd0;
            uart_start <= 1'b0;
            uart_data <= 8'd0;
        end else begin
            uart_start <= 1'b0;
            if (!sending) begin
                if (start) begin
                    sending <= 1'b1;
                    idx <= 4'd0;
                    uart_data <= frame[0];
                    uart_start <= 1'b1;
                end
            end else if (!uart_busy && !uart_start) begin
                if (idx == 4'd14)
                    sending <= 1'b0;
                else begin
                    idx <= idx + 4'd1;
                    uart_data <= frame[idx + 4'd1];
                    uart_start <= 1'b1;
                end
            end
        end
    end
endmodule
