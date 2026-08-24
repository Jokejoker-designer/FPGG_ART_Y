`timescale 1ns/1ps
// Signed floor-div, denom > 0. Matches Python n // d.
module floordiv_s48 (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic signed [47:0] numer,
    input  logic [15:0] denom,
    output logic signed [31:0] quot,
    output logic done
);
    typedef enum logic [1:0] {S_IDLE, S_RUN, S_FIX, S_DONE} st_t;
    st_t st;
    logic [47:0] absn;
    logic [48:0] rem;
    logic [48:0] d_ext;
    logic [5:0] bit_i;
    logic [47:0] uq;
    logic neg;
    logic [48:0] trial;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            done <= 1'b0;
            quot <= 32'sd0;
            absn <= 48'd0;
            rem <= 48'd0;
            d_ext <= 48'd0;
            bit_i <= 6'd0;
            uq <= 48'd0;
            neg <= 1'b0;
        end else begin
            done <= 1'b0;
            unique case (st)
                S_IDLE: if (start) begin
                    neg <= numer[47];
                    absn <= numer[47] ? -numer : numer;
                    rem <= 49'd0;
                    d_ext <= {33'd0, denom};
                    bit_i <= 6'd47;
                    uq <= 48'd0;
                    st <= S_RUN;
                end
                S_RUN: begin
                    trial = {rem[47:0], absn[bit_i]};
                    if (trial >= d_ext) begin
                        rem <= trial - d_ext;
                        uq[bit_i] <= 1'b1;
                    end else
                        rem <= trial;
                    if (bit_i == 6'd0)
                        st <= S_FIX;
                    else
                        bit_i <= bit_i - 6'd1;
                end
                S_FIX: begin
                    if (!neg)
                        quot <= uq[31:0];
                    else if (rem == 49'd0)
                        quot <= -uq[31:0];
                    else
                        quot <= -uq[31:0] - 32'sd1;
                    st <= S_DONE;
                end
                S_DONE: begin
                    done <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
