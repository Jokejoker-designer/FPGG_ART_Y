`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
// 01R UART + Q1. Host sends INT16 hidden; FPGA encodes then routes.
// Never accepts a precomputed Hamming winner.
module eam02q_uart (
    input  logic clk,
    input  logic rst_n,
    input  logic rx,
    output logic tx,
    output logic last_hit,
    output logic core_idle
);
    localparam int CLK_HZ = 100_000_000;
    localparam int BAUD   = 115200;
    localparam int MAXP   = 40;
    localparam int RLEN   = 20;

    logic [7:0] rx_data;
    logic       rx_valid, tx_start, tx_busy;
    logic [7:0] tx_data;
    logic       tx_i;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(rx), .data(rx_data), .valid(rx_valid)
    );
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(tx_start), .data(tx_data),
        .tx(tx_i), .busy(tx_busy)
    );
    assign tx = tx_i;

    logic signed [15:0] hmem [0:127];
    logic        q1_start, q1_busy, q1_done;
    logic [6:0]  q1_j;
    logic [63:0] q1_key;
    logic        enc_only, after_enc_map;

    eam02q_q1 u_q1 (
        .clk(clk), .rst_n(rst_n),
        .start(q1_start), .h(hmem[q1_j]), .j(q1_j),
        .busy(q1_busy), .done(q1_done), .key(q1_key)
    );

    logic        qstart, do_map, soft_rst, clr_stat, idle, rvalid, hit;
    logic [63:0] qkey;
    logic [127:0] qvec, ovec;
    logic [7:0]  qtok, otok, oconf, epoch, omarg, hit_max_r, marg_r;
    logic [6:0]  oham, osec;
    logic [15:0] ocand, oovf;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;
    (* keep = "true" *) logic vec_obs;
    (* keep = "true" *) logic key_obs;

    assign last_hit = hit;

    eam01r_core u_core (
        .clk(clk), .rst_n(rst_n),
        .query_start(qstart), .do_map(do_map),
        .query_key(qkey), .context_vec(qvec), .context_token(qtok),
        .hit_max(hit_max_r), .margin_min(marg_r),
        .soft_rst(soft_rst), .clr_stat(clr_stat),
        .idle(idle), .result_valid(rvalid), .hit(hit),
        .out_token(otok), .out_vector(ovec), .out_confidence(oconf),
        .out_hamming(oham), .out_second(osec), .out_margin(omarg),
        .cand_n(ocand), .ovf_n(oovf),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .epoch(epoch)
    );

    always_ff @(posedge clk) begin
        if (rvalid)
            vec_obs <= ^{ovec, otok, oconf, oham, osec, omarg};
        if (q1_done)
            key_obs <= ^q1_key;
    end

    typedef enum logic [3:0] {
        S_SYNC, S_CMD, S_LEN, S_PAY, S_XOR, S_GO, S_PACK, S_PRES,
        S_ENC, S_WAIT, S_TX
    } st_t;
    st_t st;
    logic [7:0] cmd, n, acc, got, rbuf [0:19];
    logic [5:0] pi, ti;
    logic       tx_armed, lat_hit;
    logic [7:0] lat_tok;
    logic [6:0] lat_ham, lat_sec;
    logic [63:0] lat_key;

    assign core_idle = idle && !q1_busy && (st == S_SYNC);

    function automatic logic [7:0] rxor;
        int k;
        logic [7:0] x;
        begin
            x = 8'd0;
            for (k = 0; k < 19; k++)
                x = x ^ rbuf[k];
            return x;
        end
    endfunction

    task automatic fill_reply(input logic [7:0] kind, input logic is_res);
        begin
            rbuf[0] = 8'h5A;
            rbuf[1] = kind;
            rbuf[2] = {key_obs, vec_obs, idle, is_res, lat_hit};
            rbuf[3] = is_res ? lat_tok : 8'd0;
            rbuf[4] = is_res ? {1'b0, lat_ham} : hit_max_r;
            rbuf[5] = is_res ? {1'b0, lat_sec} : marg_r;
            rbuf[6] = hit_cnt[7:0];
            rbuf[7] = hit_cnt[15:8];
            rbuf[8] = hit_cnt[23:16];
            rbuf[9] = hit_cnt[31:24];
            rbuf[10] = miss_cnt[7:0];
            rbuf[11] = miss_cnt[15:8];
            rbuf[12] = miss_cnt[23:16];
            rbuf[13] = miss_cnt[31:24];
            rbuf[14] = qry_cnt[7:0];
            rbuf[15] = qry_cnt[15:8];
            rbuf[16] = ocand[7:0];
            rbuf[17] = oovf[7:0];
            rbuf[18] = epoch;
            rbuf[19] = rxor();
        end
    endtask

    task automatic fill_enc(input logic [63:0] k);
        begin
            rbuf[0] = 8'h5A;
            rbuf[1] = 8'h84;
            rbuf[2] = {key_obs, vec_obs, idle, 1'b1, 1'b0};
            rbuf[3] = k[7:0];
            rbuf[4] = k[15:8];
            rbuf[5] = k[23:16];
            rbuf[6] = k[31:24];
            rbuf[7] = k[39:32];
            rbuf[8] = k[47:40];
            rbuf[9] = k[55:48];
            rbuf[10] = k[63:56];
            rbuf[11] = 8'h51;
            rbuf[12] = 8'h31;
            rbuf[13] = 8'd0;
            rbuf[14] = 8'd0;
            rbuf[15] = 8'd0;
            rbuf[16] = 8'd0;
            rbuf[17] = 8'd0;
            rbuf[18] = epoch;
            rbuf[19] = rxor();
        end
    endtask

    logic [7:0] pay [0:39];
    integer hi;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_SYNC;
            qstart <= 1'b0;
            do_map <= 1'b0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            q1_start <= 1'b0;
            enc_only <= 1'b0;
            after_enc_map <= 1'b0;
            tx_start <= 1'b0;
            tx_armed <= 1'b0;
            hit_max_r <= 8'(E1_HIT_MAX0);
            marg_r <= 8'(E1_MARGIN0);
            lat_hit <= 1'b0;
            lat_tok <= 8'd0;
            lat_ham <= 7'd64;
            lat_sec <= 7'd64;
            lat_key <= 64'd0;
            for (hi = 0; hi < 128; hi++)
                hmem[hi] <= 16'sd0;
        end else begin
            qstart <= 1'b0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            q1_start <= 1'b0;
            unique case (st)
                S_SYNC: if (rx_valid && rx_data == 8'hA5) begin
                    acc <= 8'hA5;
                    st <= S_CMD;
                end
                S_CMD: if (rx_valid) begin
                    cmd <= rx_data;
                    acc <= acc ^ rx_data;
                    st <= S_LEN;
                end
                S_LEN: if (rx_valid) begin
                    n <= rx_data;
                    acc <= acc ^ rx_data;
                    pi <= 6'd0;
                    st <= (rx_data == 8'd0) ? S_XOR :
                          (rx_data > MAXP[7:0]) ? S_SYNC : S_PAY;
                end
                S_PAY: if (rx_valid) begin
                    pay[pi] <= rx_data;
                    acc <= acc ^ rx_data;
                    if (pi + 6'd1 == {2'b0, n[5:0]})
                        st <= S_XOR;
                    else
                        pi <= pi + 6'd1;
                end
                S_XOR: if (rx_valid) begin
                    got <= rx_data;
                    st <= S_GO;
                end
                S_GO: begin
                    if (got != acc) begin
                        fill_reply(8'h8E, 1'b0);
                        ti <= 6'd0;
                        st <= S_TX;
                    end else unique case (cmd)
                        8'h01: begin
                            fill_reply(8'h81, 1'b0);
                            rbuf[3] = 8'h51;
                            rbuf[4] = 8'h31;
                            rbuf[5] = 8'h52;
                            rbuf[19] = rxor();
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h06: begin
                            fill_reply(8'h83, 1'b0);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h04: begin
                            soft_rst <= 1'b1;
                            st <= S_PACK;
                        end
                        8'h05: begin
                            clr_stat <= 1'b1;
                            st <= S_PACK;
                        end
                        8'h07: begin
                            if (n >= 8'd1)
                                hit_max_r <= pay[0];
                            st <= S_PACK;
                        end
                        8'h08: begin
                            if (n >= 8'd1)
                                marg_r <= pay[0];
                            st <= S_PACK;
                        end
                        8'h09: begin
                            // LOADH: blk[0] + 16 data bytes → 8 INT16 LE
                            if (n != 8'd17 || pay[0] > 8'd15) begin
                                fill_reply(8'h8E, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                for (hi = 0; hi < 8; hi++)
                                    hmem[{pay[0][3:0], hi[2:0]}] <=
                                        $signed({pay[1+2*hi+1], pay[1+2*hi]});
                                st <= S_PACK;
                            end
                        end
                        8'h0C: begin
                            if (!idle || q1_busy) begin
                                fill_reply(8'h8E, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                enc_only <= 1'b1;
                                after_enc_map <= 1'b0;
                                q1_start <= 1'b1;
                                st <= S_ENC;
                            end
                        end
                        8'h0A, 8'h0B: begin
                            if (n != 8'd17 || !idle || q1_busy) begin
                                fill_reply(8'h8E, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                qvec <= {pay[15],pay[14],pay[13],pay[12],
                                         pay[11],pay[10],pay[9],pay[8],
                                         pay[7],pay[6],pay[5],pay[4],
                                         pay[3],pay[2],pay[1],pay[0]};
                                qtok <= pay[16];
                                do_map <= (cmd == 8'h0A);
                                enc_only <= 1'b0;
                                after_enc_map <= 1'b1;
                                q1_start <= 1'b1;
                                st <= S_ENC;
                            end
                        end
                        8'h02, 8'h03: begin
                            if (n != 8'd25 || !idle) begin
                                fill_reply(8'h8E, 1'b0);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                qkey <= {pay[7],pay[6],pay[5],pay[4],
                                         pay[3],pay[2],pay[1],pay[0]};
                                qvec <= {pay[23],pay[22],pay[21],pay[20],
                                         pay[19],pay[18],pay[17],pay[16],
                                         pay[15],pay[14],pay[13],pay[12],
                                         pay[11],pay[10],pay[9],pay[8]};
                                qtok <= pay[24];
                                do_map <= (cmd == 8'h02);
                                qstart <= 1'b1;
                                st <= S_WAIT;
                            end
                        end
                        default: begin
                            fill_reply(8'h8E, 1'b0);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                    endcase
                end
                S_ENC: if (q1_done) begin
                    lat_key <= q1_key;
                    if (enc_only) begin
                        fill_enc(q1_key);
                        ti <= 6'd0;
                        st <= S_TX;
                    end else begin
                        qkey <= q1_key;
                        qstart <= 1'b1;
                        st <= S_WAIT;
                    end
                end
                S_PACK: begin
                    fill_reply(8'h83, 1'b0);
                    ti <= 6'd0;
                    st <= S_TX;
                end
                S_PRES: begin
                    fill_reply(8'h82, 1'b1);
                    ti <= 6'd0;
                    st <= S_TX;
                end
                S_WAIT: if (rvalid) begin
                    lat_hit <= hit;
                    lat_tok <= otok;
                    lat_ham <= oham;
                    lat_sec <= osec;
                    st <= S_PRES;
                end
                S_TX: begin
                    if (!tx_armed && !tx_busy) begin
                        tx_data <= rbuf[ti];
                        tx_start <= 1'b1;
                        tx_armed <= 1'b1;
                    end else if (tx_armed && tx_busy) begin
                        tx_start <= 1'b0;
                        tx_armed <= 1'b0;
                        if (ti == 6'd19)
                            st <= S_SYNC;
                        else
                            ti <= ti + 6'd1;
                    end else
                        tx_start <= 1'b0;
                end
                default: st <= S_SYNC;
            endcase
        end
    end
endmodule
