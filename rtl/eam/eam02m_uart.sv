`timescale 1ns/1ps
import a7eam00_pkg::*;
import a7eam01r_pkg::*;
import a7eam02m_pkg::*;
// 02M transport. Raw 01R MAP/PROBE (0x02/0x03) are not exposed.
module eam02m_uart (
    input  logic clk,
    input  logic rst_n,
    input  logic rx,
    output logic tx,
    output logic last_hit,
    output logic core_idle
);
    localparam int CLK_HZ = 100_000_000;
    localparam int BAUD   = 115200;
    localparam int MAXP   = 48;
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

    logic        open_s, bind_s, probe_s, toff_s, soft_rst, clr_stat;
    logic        idle, rvalid, hit, col, nack, teach;
    logic [7:0]  in_ep, in_tok, ncode, oep, otok, ocue, omarg, epoch;
    logic [63:0] in_key;
    logic [127:0] in_vec;
    logic [7:0]  hit_max_r, marg_r;
    logic [6:0]  oham, osec;
    logic [15:0] ocand, oovf;
    logic [31:0] hit_cnt, miss_cnt, qry_cnt;
    (* keep = "true" *) logic vec_obs;

    assign core_idle = idle;
    assign last_hit = hit;

    eam02m_core u_core (
        .clk(clk), .rst_n(rst_n),
        .open_start(open_s), .bind_start(bind_s), .probe_start(probe_s),
        .teacher_off_cmd(toff_s), .soft_rst(soft_rst), .clr_stat(clr_stat),
        .in_episode(in_ep), .in_token(in_tok), .in_key(in_key), .in_vec(in_vec),
        .hit_max(hit_max_r), .margin_min(marg_r),
        .idle(idle), .result_valid(rvalid),
        .hit(hit), .collide(col), .nack(nack), .nack_code(ncode),
        .out_episode(oep), .out_token(otok), .out_cue_n(ocue),
        .out_hamming(oham), .out_second(osec), .out_margin(omarg),
        .teacher_off(teach),
        .hit_cnt(hit_cnt), .miss_cnt(miss_cnt), .qry_cnt(qry_cnt),
        .cand_n(ocand), .ovf_n(oovf), .epoch(epoch)
    );

    always_ff @(posedge clk)
        if (rvalid)
            vec_obs <= ^{otok, oep, ocue, oham, osec, omarg};

    typedef enum logic [3:0] {
        S_SYNC, S_CMD, S_LEN, S_PAY, S_XOR, S_GO, S_FOLD, S_ISSUE,
        S_PACK, S_WAIT, S_TX
    } st_t;
    st_t st;
    logic [7:0] cmd, n, acc, got, rbuf [0:19];
    logic [5:0] pi, ti;
    logic       tx_armed;
    logic [7:0] pay [0:47];
    logic [63:0] fold_acc;
    logic [5:0]  fold_i, fold_n;
    logic [7:0]  lat_kind;
    logic        lat_hit, lat_col, lat_nack, lat_teach;
    logic [7:0]  lat_tok, lat_ep, lat_cue, lat_ncode;
    logic [6:0]  lat_ham, lat_sec;
    logic        do_txt, txt_is_bind;

    function automatic logic [7:0] rxor;
        int i;
        logic [7:0] x;
        begin
            x = 8'd0;
            for (i = 0; i < 19; i++)
                x = x ^ rbuf[i];
            return x;
        end
    endfunction

    task automatic fill_reply(
        input logic [7:0] kind,
        input logic ihit, icol, inack, iteach,
        input logic [7:0] itok, iep, icue, incode,
        input logic [6:0] iham, isec
    );
        begin
            rbuf[0] = 8'h5A;
            rbuf[1] = kind;
            rbuf[2] = {3'd0, iteach, icol, idle, 1'b1, ihit};
            rbuf[3] = itok;
            rbuf[4] = {1'b0, iham};
            rbuf[5] = inack ? incode : {1'b0, isec};
            rbuf[6] = hit_cnt[7:0];
            rbuf[7] = hit_cnt[15:8];
            rbuf[8] = hit_cnt[23:16];
            rbuf[9] = hit_cnt[31:24];
            rbuf[10] = miss_cnt[7:0];
            rbuf[11] = miss_cnt[15:8];
            rbuf[12] = miss_cnt[23:16];
            rbuf[13] = miss_cnt[31:24];
            rbuf[14] = iep;
            rbuf[15] = icue;
            rbuf[16] = ocand[7:0];
            rbuf[17] = oovf[7:0];
            rbuf[18] = epoch;
            rbuf[19] = rxor();
        end
    endtask

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_SYNC;
            open_s <= 1'b0;
            bind_s <= 1'b0;
            probe_s <= 1'b0;
            toff_s <= 1'b0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            tx_start <= 1'b0;
            tx_armed <= 1'b0;
            hit_max_r <= 8'(E2M_HIT_MAX0);
            marg_r <= 8'(E2M_MARGIN0);
            lat_hit <= 1'b0;
            lat_col <= 1'b0;
            lat_nack <= 1'b0;
            lat_teach <= 1'b0;
            lat_tok <= 8'd0;
            lat_ep <= 8'd0;
            lat_cue <= 8'd0;
            lat_ham <= 7'd64;
            lat_sec <= 7'd64;
            lat_ncode <= 8'd0;
            lat_kind <= 8'h83;
        end else begin
            open_s <= 1'b0;
            bind_s <= 1'b0;
            probe_s <= 1'b0;
            toff_s <= 1'b0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
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
                        lat_kind <= 8'h8E;
                        lat_nack <= 1'b1;
                        lat_ncode <= 8'hEE;
                        fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                        ti <= 6'd0;
                        st <= S_TX;
                    end else unique case (cmd)
                        8'h01: begin
                            fill_reply(8'h81, 1'b0, 1'b0, 1'b0, teach, 8'h4D, 8'd0, 8'd0, 8'd0, 7'h32, 7'h4D);
                            rbuf[3] = 8'h4D;
                            rbuf[4] = 8'h32;
                            rbuf[5] = 8'h4D;
                            rbuf[19] = rxor();
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h04: begin
                            soft_rst <= 1'b1;
                            lat_kind <= 8'h83;
                            st <= S_PACK;
                        end
                        8'h05, 8'h06: begin
                            if (cmd == 8'h05)
                                clr_stat <= 1'b1;
                            lat_kind <= 8'h83;
                            st <= S_PACK;
                        end
                        8'h07: begin
                            if (n >= 8'd1)
                                hit_max_r <= pay[0];
                            lat_kind <= 8'h83;
                            st <= S_PACK;
                        end
                        8'h08: begin
                            if (n >= 8'd1)
                                marg_r <= pay[0];
                            lat_kind <= 8'h83;
                            st <= S_PACK;
                        end
                        8'h13: begin
                            toff_s <= 1'b1;
                            lat_kind <= 8'h93;
                            lat_teach <= 1'b1;
                            st <= S_PACK;
                        end
                        8'h10: begin
                            if (n != 8'd17 || !idle) begin
                                lat_kind <= 8'h8E;
                                fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                in_vec <= {pay[15],pay[14],pay[13],pay[12],
                                           pay[11],pay[10],pay[9],pay[8],
                                           pay[7],pay[6],pay[5],pay[4],
                                           pay[3],pay[2],pay[1],pay[0]};
                                in_tok <= pay[16];
                                lat_kind <= 8'h90;
                                open_s <= 1'b1;
                                st <= S_WAIT;
                            end
                        end
                        8'h11: begin
                            if (n != 8'd9 || !idle) begin
                                lat_kind <= 8'h8E;
                                fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                in_ep <= pay[0];
                                in_key <= {pay[8],pay[7],pay[6],pay[5],
                                           pay[4],pay[3],pay[2],pay[1]};
                                lat_kind <= 8'h91;
                                bind_s <= 1'b1;
                                st <= S_WAIT;
                            end
                        end
                        8'h12: begin
                            if (n != 8'd8 || !idle) begin
                                lat_kind <= 8'h8E;
                                fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                in_key <= {pay[7],pay[6],pay[5],pay[4],
                                           pay[3],pay[2],pay[1],pay[0]};
                                lat_kind <= 8'h92;
                                probe_s <= 1'b1;
                                st <= S_WAIT;
                            end
                        end
                        8'h14, 8'h15: begin
                            if (!idle) begin
                                lat_kind <= 8'h8E;
                                fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                do_txt <= 1'b1;
                                txt_is_bind <= (cmd == 8'h14);
                                if (cmd == 8'h14) begin
                                    in_ep <= pay[0];
                                    fold_n <= pay[1][5:0];
                                    fold_i <= 6'd0;
                                    fold_acc <= E2M_FOLD_IV;
                                    lat_kind <= 8'h91;
                                    if (n < 8'd2 || pay[1] == 8'd0 ||
                                        (8'(pay[1]) + 8'd2) != n) begin
                                        lat_nack <= 1'b1;
                                        lat_ncode <= E2M_NACK_EMPTY;
                                        lat_kind <= 8'h9E;
                                        fill_reply(8'h9E, 1'b0, 1'b0, 1'b1, teach, 8'd0, pay[0], 8'd0, E2M_NACK_EMPTY, 7'd64, 7'd64);
                                        ti <= 6'd0;
                                        st <= S_TX;
                                    end else
                                        st <= S_FOLD;
                                end else begin
                                    fold_n <= pay[0][5:0];
                                    fold_i <= 6'd0;
                                    fold_acc <= E2M_FOLD_IV;
                                    lat_kind <= 8'h92;
                                    if (n < 8'd1 || pay[0] == 8'd0 ||
                                        (8'(pay[0]) + 8'd1) != n) begin
                                        lat_nack <= 1'b1;
                                        lat_ncode <= E2M_NACK_EMPTY;
                                        lat_kind <= 8'h9E;
                                        fill_reply(8'h9E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, E2M_NACK_EMPTY, 7'd64, 7'd64);
                                        ti <= 6'd0;
                                        st <= S_TX;
                                    end else
                                        st <= S_FOLD;
                                end
                            end
                        end
                        default: begin
                            lat_kind <= 8'h8E;
                            fill_reply(8'h8E, 1'b0, 1'b0, 1'b1, teach, 8'd0, 8'd0, 8'd0, 8'hEE, 7'd64, 7'd64);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                    endcase
                end
                S_FOLD: begin
                    if (fold_i < fold_n) begin
                        if (txt_is_bind)
                            fold_acc <= e2m_fold_step(fold_acc, pay[6'(2 + fold_i)]);
                        else
                            fold_acc <= e2m_fold_step(fold_acc, pay[6'(1 + fold_i)]);
                        fold_i <= fold_i + 6'd1;
                    end else
                        st <= S_ISSUE;
                end
                S_ISSUE: begin
                    in_key <= fold_acc;
                    if (txt_is_bind)
                        bind_s <= 1'b1;
                    else
                        probe_s <= 1'b1;
                    st <= S_WAIT;
                end
                S_PACK: begin
                    lat_hit <= 1'b0;
                    lat_col <= 1'b0;
                    lat_nack <= 1'b0;
                    lat_tok <= 8'd0;
                    lat_ep <= 8'd0;
                    lat_cue <= 8'd0;
                    lat_ham <= 7'd64;
                    lat_sec <= 7'd64;
                    fill_reply(lat_kind, 1'b0, 1'b0, 1'b0, teach, 8'd0, 8'd0, 8'd0, 8'd0, 7'd64, 7'd64);
                    ti <= 6'd0;
                    st <= S_TX;
                end
                S_WAIT: if (rvalid) begin
                    lat_hit <= hit;
                    lat_col <= col;
                    lat_nack <= nack;
                    lat_ncode <= ncode;
                    lat_teach <= teach;
                    lat_tok <= otok;
                    lat_ep <= oep;
                    lat_cue <= ocue;
                    lat_ham <= oham;
                    lat_sec <= osec;
                    fill_reply(nack ? 8'h9E : lat_kind, hit, col, nack, teach,
                               otok, oep, ocue, ncode, oham, osec);
                    ti <= 6'd0;
                    st <= S_TX;
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
