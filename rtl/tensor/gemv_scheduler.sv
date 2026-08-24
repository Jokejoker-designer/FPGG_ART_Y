`timescale 1ns/1ps
// GEMV: 1 act broadcast x 128 weights / cycle. 1-cycle BRAM latency.
module gemv_scheduler (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               start,
    input  logic               acc_cont,
    input  logic [8:0]         k_len,
    output logic               busy,
    output logic               done,
    output logic               clr,
    output logic               en,
    output logic [7:0]         k_addr,
    input  logic [127:0]       act_row,
    input  logic [1023:0]      w_row,
    output logic signed [15:0] a [0:127],
    output logic signed [7:0]  b [0:127]
);
    typedef enum logic [1:0] {IDLE, PRE, RUN, DONE} st_t;
    st_t st;
    logic [8:0] k;
    integer i;
    logic signed [15:0] act0;
    logic acc_r;

    assign act0 = $signed(act_row[15:0]);
    always_comb begin
        for (i = 0; i < 128; i = i + 1) begin
            a[i] = act0;
            b[i] = $signed(w_row[i*8 +: 8]);
        end
    end

    assign busy = (st == PRE) || (st == RUN);
    // Block RAM is sync-read: issue addr N one cycle before MAC of row N.
    assign k_addr = (st == RUN) ? (k[7:0] + 8'd1) : k[7:0];
    assign en  = (st == RUN);
    assign clr = (st == PRE) && !acc_r;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= IDLE;
            k <= 9'd0;
            done <= 1'b0;
            acc_r <= 1'b0;
        end else begin
            done <= 1'b0;
            unique case (st)
                IDLE: if (start) begin
                    k <= 9'd0;
                    acc_r <= acc_cont;
                    st <= PRE;
                end
                PRE: begin
                    k <= 9'd0;
                    st <= RUN;
                end
                RUN: begin
                    if (k + 9'd1 >= k_len) st <= DONE;
                    else k <= k + 9'd1;
                end
                DONE: begin
                    done <= 1'b1;
                    st <= IDLE;
                end
                default: st <= IDLE;
            endcase
        end
    end
endmodule
