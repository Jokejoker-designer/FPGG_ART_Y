`timescale 1ns/1ps
import a7eam03e_pkg::*;
// 03E-A0 UART. No 01R MAP/PROBE.
// A0.3 lane copy of eam03e_uart.sv. Protocol and PING ident deliberately
// unchanged (contract A7-EAM-03E-A03 keeps the UART surface fixed), so the
// loaded bit must be identified by SHA256, not by ident bytes.
module eam03e_a03_uart (
    input  logic clk,
    input  logic rst_n,
    input  logic rx,
    output logic tx,
    output logic last_upd,
    output logic core_idle
);
    localparam int CLK_HZ = 100_000_000;
    localparam int BAUD   = 115200;
    localparam int MAXP   = 48;
    localparam int RLEN   = 20;

    logic [7:0] rx_data, tx_data;
    logic       rx_valid, tx_start, tx_busy, tx_i;
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(rx), .data(rx_data), .valid(rx_valid)
    );
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(tx_start), .data(tx_data),
        .tx(tx_i), .busy(tx_busy)
    );
    assign tx = tx_i;

    logic        learn_r, freeze_r, label_same, enc_slot;
    logic        start_seed, start_pair, start_enc;
    logic [31:0] seed_in, seed_used;
    logic [7:0]  nA, nB;
    logic [7:0]  seqA [0:E3_TMAX-1];
    logic [7:0]  seqB [0:E3_TMAX-1];
    logic        idle, rvalid, upd;
    logic [6:0]  o_dh;
    logic [15:0] o_d1;
    logic [63:0] o_cue;

    assign core_idle = idle;
    assign last_upd = upd;

    eam03e_a03_core u_core (
        .clk(clk), .rst_n(rst_n),
        .start_seed(start_seed), .start_pair(start_pair), .start_enc(start_enc),
        .seed_in(seed_in), .learn(learn_r), .freeze(freeze_r),
        .label_same(label_same), .enc_slot(enc_slot),
        .nA(nA), .nB(nB), .seqA(seqA), .seqB(seqB),
        .idle(idle), .result_valid(rvalid), .updated(upd),
        .dH(o_dh), .d1(o_d1), .cue(o_cue), .seed_used(seed_used)
    );

    typedef enum logic [3:0] {
        S_SYNC, S_CMD, S_LEN, S_PAY, S_XOR, S_GO, S_WAIT, S_TX
    } st_t;
    st_t st;
    logic [7:0] cmd, n, acc, got, rbuf [0:19], pay [0:47];
    logic [5:0] pi, ti;
    logic       tx_armed;
    logic [7:0] lat_kind;

    function automatic logic [7:0] rxor;
        int i;
        logic [7:0] x;
        x = 8'd0;
        for (i = 0; i < 19; i++)
            x = x ^ rbuf[i];
        return x;
    endfunction

    task automatic fill_pair(input logic [7:0] kind);
        begin
            rbuf[0] = 8'h5A;
            rbuf[1] = kind;
            rbuf[2] = {5'd0, upd, freeze_r, learn_r};
            rbuf[3] = {1'b0, o_dh};
            rbuf[4] = o_d1[7:0];
            rbuf[5] = o_d1[15:8];
            rbuf[6] = o_cue[7:0];
            rbuf[7] = o_cue[15:8];
            rbuf[8] = o_cue[23:16];
            rbuf[9] = o_cue[31:24];
            rbuf[10] = o_cue[39:32];
            rbuf[11] = o_cue[47:40];
            rbuf[12] = o_cue[55:48];
            rbuf[13] = o_cue[63:56];
            rbuf[14] = nA;
            rbuf[15] = nB;
            rbuf[16] = seed_used[7:0];
            rbuf[17] = 8'd0;
            rbuf[18] = {6'd0, freeze_r, learn_r};
            rbuf[19] = rxor();
        end
    endtask

    integer zi;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            st <= S_SYNC;
            start_seed <= 1'b0;
            start_pair <= 1'b0;
            start_enc <= 1'b0;
            tx_start <= 1'b0;
            tx_armed <= 1'b0;
            learn_r <= 1'b0;
            freeze_r <= 1'b0;
            label_same <= 1'b0;
            enc_slot <= 1'b0;
            seed_in <= E3_SEED0;
            nA <= 8'd0;
            nB <= 8'd0;
            lat_kind <= 8'h83;
        end else begin
            start_seed <= 1'b0;
            start_pair <= 1'b0;
            start_enc <= 1'b0;
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
                        fill_pair(8'h8E);
                        ti <= 6'd0;
                        st <= S_TX;
                    end else unique case (cmd)
                        8'h01: begin
                            fill_pair(8'h81);
                            rbuf[3] = 8'h33;
                            rbuf[4] = 8'h41;
                            rbuf[5] = 8'h30;
                            rbuf[19] = rxor();
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h04: begin
                            seed_in <= E3_SEED0;
                            start_seed <= 1'b1;
                            lat_kind <= 8'h83;
                            st <= S_WAIT;
                        end
                        8'h13: begin
                            learn_r <= 1'b0;
                            freeze_r <= 1'b1;
                            fill_pair(8'h93);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h20: begin
                            if (n >= 8'd1) begin
                                learn_r <= pay[0][0];
                                freeze_r <= pay[0][1];
                            end
                            fill_pair(8'h83);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                        8'h21: begin
                            if (n >= 8'd4)
                                seed_in <= {pay[3], pay[2], pay[1], pay[0]};
                            start_seed <= 1'b1;
                            lat_kind <= 8'h83;
                            st <= S_WAIT;
                        end
                        8'h22: begin
                            if (!idle || n < 8'd2) begin
                                fill_pair(8'h8E);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                if (pay[0] == 8'd0) begin
                                    nA <= pay[1];
                                    for (zi = 0; zi < E3_TMAX; zi++)
                                        if (zi < int'(pay[1]) && (zi + 2) < MAXP)
                                            seqA[zi] <= pay[zi + 2];
                                end else begin
                                    nB <= pay[1];
                                    for (zi = 0; zi < E3_TMAX; zi++)
                                        if (zi < int'(pay[1]) && (zi + 2) < MAXP)
                                            seqB[zi] <= pay[zi + 2];
                                end
                                fill_pair(8'h82);
                                ti <= 6'd0;
                                st <= S_TX;
                            end
                        end
                        8'h23: begin
                            if (!idle) begin
                                fill_pair(8'h8E);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                label_same <= (n >= 8'd1) && pay[0][0];
                                start_pair <= 1'b1;
                                lat_kind <= 8'hA3;
                                st <= S_WAIT;
                            end
                        end
                        8'h24: begin
                            if (!idle) begin
                                fill_pair(8'h8E);
                                ti <= 6'd0;
                                st <= S_TX;
                            end else begin
                                enc_slot <= (n >= 8'd1) && pay[0][0];
                                start_enc <= 1'b1;
                                lat_kind <= 8'hA4;
                                st <= S_WAIT;
                            end
                        end
                        default: begin
                            fill_pair(8'h8E);
                            ti <= 6'd0;
                            st <= S_TX;
                        end
                    endcase
                end
                S_WAIT: if (rvalid) begin
                    fill_pair(lat_kind);
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
