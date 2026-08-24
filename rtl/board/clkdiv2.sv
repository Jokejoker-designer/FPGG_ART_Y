`timescale 1ns/1ps
// Divide-by-2 BUFG. A7-LM-03 sequential core + UART run at 50 MHz.
module clkdiv2 (
    input  logic clk_in,
    input  logic rst_n,
    output logic clk_out
);
    logic q;
    always_ff @(posedge clk_in) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= ~q;
    end
    BUFG u_buf (.I(q), .O(clk_out));
endmodule
