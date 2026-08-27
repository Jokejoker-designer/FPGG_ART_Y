`timescale 1ns/1ps
// 100 MHz -> 12.5 MHz (80 ns) for E2 native_v1 existence core clock.
module clkdiv8 (
    input  logic clk_in,
    input  logic rst_n,
    output logic clk_out
);
    logic [2:0] cnt;
    logic       tick;

    always_ff @(posedge clk_in) begin
        if (!rst_n) begin
            cnt  <= 3'd0;
            tick <= 1'b0;
        end else begin
            tick <= (cnt == 3'd7);
            cnt  <= cnt + 3'd1;
        end
    end

    BUFG u_buf (.I(tick), .O(clk_out));
endmodule
