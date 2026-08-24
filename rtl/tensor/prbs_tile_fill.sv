`timescale 1ns/1ps
// Bit-identical to python/ref/fixed_gemm.py fill_tiles.
module prbs_tile_fill (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic         mode,
    input  logic [3:0]   M,
    input  logic [7:0]   N,
    input  logic [8:0]   K,
    input  logic [15:0]  k_base,
    input  logic [1:0]   kind, // 0=W+A, 1=W only, 2=A only
    input  logic [31:0]  seed0,
    input  logic [31:0]  i_case,
    input  logic         corner,
    input  logic         satc,
    output logic         busy,
    output logic         done,
    output logic         w_wr_en,
    output logic [7:0]   w_wr_k,
    output logic [2:0]   w_wr_chunk,
    output logic [127:0] w_wr_data,
    output logic         a_wr_en,
    output logic [7:0]   a_wr_k,
    output logic [127:0] a_wr_data
);
    typedef enum logic [2:0] {IDLE, WSKIP, ASKIP, FW, FA, DONE} st_t;
    st_t st;
    logic [31:0] sw, sa, w0, w1, w2, nw;
    logic [8:0]  kk;
    logic [4:0]  step;
    logic [2:0]  mm;
    logic [15:0] sk_row;
    logic [4:0]  sk;
    logic [127:0] arow;
    logic [15:0] aval;
    logic [15:0] kcur;

    function automatic [31:0] xs32(input [31:0] x);
        logic [31:0] s;
        begin
            s = x;
            s = s ^ (s << 13);
            s = s ^ (s >> 17);
            s = s ^ (s << 5);
            return s;
        end
    endfunction

    function automatic [31:0] w4(input [31:0] raw, input [7:0] c0, input [7:0] n,
                                 input sat, input do_corner, input [15:0] kcur);
        logic [31:0] o;
        integer t;
        logic [7:0] cx, b;
        begin
            o = 32'd0;
            for (t = 0; t < 4; t = t + 1) begin
                cx = c0 + t[7:0];
                if (sat) b = 8'h7F;
                else b = raw[8*t +: 8];
                if (do_corner && !sat && kcur == 16'd0 && cx == 8'd0) b = 8'h80; // -128
                if (do_corner && !sat && kcur == 16'd0 && cx == 8'd1) b = 8'h7F;
                if (cx >= n) b = 8'h00;
                o[8*t +: 8] = b;
            end
            return o;
        end
    endfunction

    assign busy = (st == WSKIP) || (st == ASKIP) || (st == FW) || (st == FA);
    assign kcur = k_base + {7'd0, kk};

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= IDLE;
            done <= 1'b0;
            w_wr_en <= 1'b0;
            a_wr_en <= 1'b0;
            kk <= 9'd0;
            step <= 5'd0;
            mm <= 3'd0;
            arow <= 128'd0;
        end else begin
            done <= 1'b0;
            w_wr_en <= 1'b0;
            a_wr_en <= 1'b0;
            unique case (st)
                IDLE: if (start) begin
                    sw <= xs32(seed0 ^ (i_case * 32'h9E3779B9));
                    sa <= xs32(seed0 ^ 32'hA5A55A5A ^ (i_case * 32'h85EBCA6B));
                    kk <= 9'd0;
                    step <= 5'd0;
                    mm <= 3'd0;
                    sk <= 5'd0;
                    sk_row <= k_base;
                    arow <= 128'd0;
                    if (k_base != 16'd0 && kind != 2'd2)
                        st <= WSKIP;
                    else if (k_base != 16'd0 && kind == 2'd2)
                        st <= ASKIP;
                    else
                        st <= (kind == 2'd2) ? FA : FW;
                end
                WSKIP: begin
                    sw <= xs32(sw);
                    if (sk == 5'd31) begin
                        sk <= 5'd0;
                        if (sk_row == 16'd1) begin
                            kk <= 9'd0;
                            step <= 5'd0;
                            if (kind == 2'd0) begin
                                sk_row <= k_base;
                                st <= ASKIP;
                            end else
                                st <= FW;
                        end else
                            sk_row <= sk_row - 16'd1;
                    end else
                        sk <= sk + 5'd1;
                end
                ASKIP: begin
                    sa <= xs32(sa);
                    if (sk[2:0] == 3'd7) begin
                        sk <= 5'd0;
                        if (sk_row == 16'd1) begin
                            kk <= 9'd0;
                            mm <= 3'd0;
                            st <= FA;
                        end else
                            sk_row <= sk_row - 16'd1;
                    end else
                        sk <= sk + 5'd1;
                end
                FW: begin
                    nw = xs32(sw);
                    sw <= nw;
                    unique case (step[1:0])
                        2'd0: w0 <= w4(nw, {step, 2'b00}, N, satc, corner, kcur);
                        2'd1: w1 <= w4(nw, {step, 2'b00}, N, satc, corner, kcur);
                        2'd2: w2 <= w4(nw, {step, 2'b00}, N, satc, corner, kcur);
                        default: begin
                            w_wr_en <= 1'b1;
                            w_wr_k <= kk[7:0];
                            w_wr_chunk <= step[4:2];
                            w_wr_data <= {w4(nw, {step, 2'b00}, N, satc, corner, kcur), w2, w1, w0};
                        end
                    endcase
                    if (step == 5'd31) begin
                        step <= 5'd0;
                        if (kk + 9'd1 >= K) begin
                            kk <= 9'd0;
                            mm <= 3'd0;
                            st <= (kind == 2'd1) ? DONE : FA;
                        end else
                            kk <= kk + 9'd1;
                    end else
                        step <= step + 5'd1;
                end
                FA: begin
                    nw = xs32(sa);
                    sa <= nw;
                    if (satc) aval = (mm < M) ? 16'h7FFF : 16'h0000;
                    else if (!mode) aval = (mm == 3'd0) ? nw[15:0] : 16'h0000;
                    else aval = (mm < M) ? nw[15:0] : 16'h0000;
                    if (corner && !satc && kcur == 16'd0 && mm == 3'd0)
                        aval = (i_case[0] == 1'b0) ? 16'h8000 : 16'h7FFF;
                    arow[mm*16 +: 16] <= aval;
                    if (mm == 3'd7) begin
                        a_wr_en <= 1'b1;
                        a_wr_k <= kk[7:0];
                        a_wr_data <= arow;
                        a_wr_data[127:112] <= aval;
                        a_wr_data[111:0] <= arow[111:0];
                        mm <= 3'd0;
                        if (kk + 9'd1 >= K) st <= DONE;
                        else kk <= kk + 9'd1;
                    end else
                        mm <= mm + 3'd1;
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
