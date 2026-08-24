`timescale 1ns/1ps
// Q1 fixed ±1 hyperplanes. law eam02q-q1-rh-v1. Add/sub only. 0 DSP.
// b_i = sign(sum_j s_ij h_j), sign(0)=0. One hidden sample per cycle.
module eam02q_q1 (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 start,
    input  logic signed [15:0]   h,
    output logic [6:0]           j,
    output logic                 busy,
    output logic                 done,
    output logic [63:0]          key
);
    `include "eam02q_q1_signs.svh"

    typedef enum logic [1:0] { S_IDLE, S_ACC, S_SIGN } st_t;
    st_t st;
    (* use_dsp = "no" *) logic signed [31:0] acc [0:63];
    logic [63:0] scol;
    logic [6:0]  jj;

    assign j = jj;
    assign busy = (st != S_IDLE);
    assign scol = Q1_COL[jj];

    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_IDLE;
            done <= 1'b0;
            key <= 64'd0;
            jj <= 7'd0;
            for (i = 0; i < 64; i++)
                acc[i] <= 32'sd0;
        end else begin
            done <= 1'b0;
            unique case (st)
                S_IDLE: begin
                    if (start) begin
                        jj <= 7'd0;
                        for (i = 0; i < 64; i++)
                            acc[i] <= 32'sd0;
                        st <= S_ACC;
                    end
                end
                S_ACC: begin
                    for (i = 0; i < 64; i++) begin
                        if (scol[i])
                            acc[i] <= acc[i] + h;
                        else
                            acc[i] <= acc[i] - h;
                    end
                    if (jj == 7'd127)
                        st <= S_SIGN;
                    else
                        jj <= jj + 7'd1;
                end
                S_SIGN: begin
                    for (i = 0; i < 64; i++)
                        key[i] <= (acc[i] > 32'sd0);
                    done <= 1'b1;
                    st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
