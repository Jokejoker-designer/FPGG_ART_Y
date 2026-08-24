`timescale 1ns/1ps
// 16-step binary search floor(sqrt(x)) for unsigned 32-bit.
module isqrt32 (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [31:0] x,
    output logic [15:0] y,
    output logic done
);
    typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} st_t;
    st_t st;
    logic [15:0] lo, hi;
    logic [4:0] iter;
    logic [16:0] mid_sum;
    logic [15:0] mid;
    logic [31:0] prod;

    assign mid_sum = {1'b0, lo} + {1'b0, hi} + 17'd1;
    assign mid = mid_sum[16:1];
    assign prod = 32'(mid) * 32'(mid);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            done <= 1'b0;
            y <= 16'd0;
            lo <= 16'd0;
            hi <= 16'd0;
            iter <= 5'd0;
        end else begin
            done <= 1'b0;
            unique case (st)
                S_IDLE: if (start) begin
                    lo <= 16'd0;
                    hi <= 16'd65535;
                    iter <= 5'd0;
                    st <= S_RUN;
                end
                S_RUN: begin
                    if (prod <= x)
                        lo <= mid;
                    else
                        hi <= mid - 16'd1;
                    if (iter == 5'd15)
                        st <= S_DONE;
                    else
                        iter <= iter + 5'd1;
                end
                S_DONE: begin
                    y <= lo;
                    done <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
