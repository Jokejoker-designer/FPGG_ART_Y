`timescale 1ns/1ps
// A7-LM-00: pin wrapper only. Core/link/UART law is the frozen Basys LM-05 copy.
import lm03_pkg::*;
module arty_a7_100_top (
    input  logic CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic uart_rxd_out,
    input  logic uart_txd_in
);
    logic core_clk, locked, rst_n, btn0_sync;
    logic [3:0] sw_sync;
    logic rx_valid;
    logic [7:0] rx_data;
    logic wr_en;
    logic [3:0] wr_bank, rd_bank, mem_bank;
    logic [11:0] wr_addr, rd_addr, mem_addr;
    logic signed [7:0] wr_data, mem_rdata;
    logic ctx_load, cmd_fwd, cmd_dumpz, cmd_dumph, cmd_dumpa, cmd_read;
    logic cmd_train, cmd_dumpg, cmd_dumpc, cmd_snap, cmd_restore, cmd_after, after_lvl;
    logic [4:0] trn_tgt;
    logic [3:0] trn_lr, ctx_n;
    logic [4:0] ctx_tok [0:7];
    logic busy, done, start_fwd, start_trn, do_snap, do_rest;
    logic after_hold;
    logic [4:0] pred;
    logic signed [31:0] logits [0:31];
    logic signed [15:0] y_reg [0:7][0:15];
    logic [7:0] attn_w [0:7][0:7];
    logic signed [15:0] dZ [0:31];
    logic signed [15:0] dH [0:15];
    logic signed [15:0] g_tok [0:15], g_pos [0:15];
    logic signed [15:0] g_head0 [0:15], g_head1 [0:15], g_headt [0:15];
    logic [15:0] wr_tok_n, wr_pos_n, wr_head_n, wr_blk_n, last_loss;
    logic tx_start, tx_busy;
    logic [7:0] tx_frame [0:14];
    logic [7:0] xor14;
    logic [5:0] dump_i;
    logic dump_z, dump_h, dump_a, dump_g, dump_c, send_pred, send_mem, rd_wait, rd_skip;
    logic signed [7:0] rd_bytes [0:7];
    logic [3:0] rd_cnt;
    logic [2:0] dump_t;
    logic [3:0] dump_d;
    logic signed [15:0] gpack [0:127];
    integer fi, gi;

    basys3_clock_gen clk_i (.clk100(CLK100MHZ), .rst(btn[0]), .clk_core(core_clk), .locked(locked));
    sync_bits #(.WIDTH(1)) rst_s (.clk(core_clk), .rst_n(locked), .async_in(btn[0]), .sync_out(btn0_sync));
    assign rst_n = locked && !btn0_sync;
    sync_bits #(.WIDTH(4)) sw_s (.clk(core_clk), .rst_n(rst_n), .async_in(sw), .sync_out(sw_sync));

    uart_rx #(.CLK_HZ(8000000), .BAUD(115200)) u_rx (
        .clk(core_clk), .rst_n(rst_n), .rx(uart_txd_in), .data(rx_data), .valid(rx_valid)
    );
    lm05_link link_i (
        .clk(core_clk), .rst_n(rst_n), .rx_valid(rx_valid), .rx_data(rx_data),
        .wr_en(wr_en), .wr_bank(wr_bank), .wr_addr(wr_addr), .wr_data(wr_data),
        .ctx_load(ctx_load), .ctx_n(ctx_n), .ctx_tok(ctx_tok),
        .cmd_fwd(cmd_fwd), .cmd_dumpz(cmd_dumpz), .cmd_dumph(cmd_dumph),
        .cmd_dumpa(cmd_dumpa), .cmd_read(cmd_read),
        .cmd_train(cmd_train), .cmd_dumpg(cmd_dumpg), .cmd_dumpc(cmd_dumpc),
        .cmd_snap(cmd_snap), .cmd_restore(cmd_restore), .cmd_after(cmd_after),
        .after_lvl(after_lvl), .trn_tgt(trn_tgt), .trn_lr(trn_lr),
        .rd_bank(rd_bank), .rd_addr(rd_addr)
    );

    assign mem_bank = wr_en ? wr_bank : rd_bank;
    assign mem_addr = wr_en ? wr_addr : (rd_wait || send_mem ? (rd_addr + {8'd0, rd_cnt}) : wr_addr);

    tiny_gpt05_core core_i (
        .clk(core_clk), .rst_n(rst_n),
        .mem_we(wr_en), .mem_bank(mem_bank), .mem_addr(mem_addr),
        .mem_wdata(wr_data), .mem_rdata(mem_rdata),
        .ctx_load(ctx_load), .ctx_n(ctx_n), .ctx_tok(ctx_tok),
        .start(start_fwd), .start_train(start_trn),
        .after_mode(after_hold || sw_sync[0]),
        .do_snap(do_snap), .do_restore(do_rest),
        .tgt(trn_tgt), .lr(trn_lr),
        .dump_t(dump_t), .dump_d(dump_d),
        .busy(busy), .done(done), .pred(pred), .logits(logits),
        .y_reg(y_reg), .attn_w(attn_w),
        .dZ(dZ), .dH(dH), .g_tok(g_tok), .g_pos(g_pos),
        .g_head0(g_head0), .g_head1(g_head1), .g_headt(g_headt),
        .wr_tok_n(wr_tok_n), .wr_pos_n(wr_pos_n), .wr_head_n(wr_head_n),
        .wr_blk_n(wr_blk_n), .last_loss(last_loss)
    );

    lm02_tx u_tx (
        .clk(core_clk), .rst_n(rst_n), .start(tx_start), .frame(tx_frame),
        .tx(uart_rxd_out), .busy(tx_busy)
    );

    always_comb begin
        for (gi = 0; gi < 32; gi = gi + 1)
            gpack[gi] = dZ[gi];
        for (gi = 0; gi < 16; gi = gi + 1) begin
            gpack[32 + gi] = dH[gi];
            gpack[48 + gi] = g_tok[gi];
            gpack[64 + gi] = g_pos[gi];
            gpack[80 + gi] = g_head0[gi];
            gpack[96 + gi] = g_head1[gi];
            gpack[112 + gi] = g_headt[gi];
        end
    end

    always_ff @(posedge core_clk) begin
        if (!rst_n) begin
            start_fwd <= 1'b0;
            start_trn <= 1'b0;
            do_snap <= 1'b0;
            do_rest <= 1'b0;
            after_hold <= 1'b0;
            send_pred <= 1'b0;
            dump_z <= 1'b0;
            dump_h <= 1'b0;
            dump_a <= 1'b0;
            dump_g <= 1'b0;
            dump_c <= 1'b0;
            dump_i <= 6'd0;
            send_mem <= 1'b0;
            rd_wait <= 1'b0;
            rd_skip <= 1'b0;
            rd_cnt <= 4'd0;
            tx_start <= 1'b0;
            dump_t <= 3'd0;
            dump_d <= 4'd0;
            for (fi = 0; fi < 8; fi = fi + 1)
                rd_bytes[fi] <= 8'sd0;
        end else begin
            start_fwd <= cmd_fwd;
            start_trn <= cmd_train;
            do_snap <= cmd_snap;
            do_rest <= cmd_restore;
            tx_start <= 1'b0;
            if (cmd_after)
                after_hold <= after_lvl;
            if (done)
                send_pred <= 1'b1;
            if (cmd_dumpz) begin dump_z <= 1'b1; dump_i <= 6'd0; end
            if (cmd_dumph) begin dump_h <= 1'b1; dump_i <= 6'd0; end
            if (cmd_dumpa) begin dump_a <= 1'b1; dump_i <= 6'd0; end
            if (cmd_dumpg) begin dump_g <= 1'b1; dump_i <= 6'd0; end
            if (cmd_dumpc) begin dump_c <= 1'b1; dump_i <= 6'd0; end
            if (cmd_read) begin
                send_mem <= 1'b0;
                rd_wait <= 1'b1;
                rd_skip <= 1'b1;
                rd_cnt <= 4'd0;
            end
            if (rd_wait) begin
                if (rd_skip)
                    rd_skip <= 1'b0;
                else begin
                    rd_bytes[rd_cnt] <= mem_rdata;
                    if (rd_cnt == 4'd7) begin
                        rd_wait <= 1'b0;
                        send_mem <= 1'b1;
                        rd_cnt <= 4'd0;
                    end else
                        rd_cnt <= rd_cnt + 4'd1;
                end
            end
            if (!tx_busy && !tx_start) begin
                if (send_pred) begin
                    send_pred <= 1'b0;
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h74;
                    tx_frame[2] <= {3'd0, pred};
                    tx_frame[3] <= last_loss[7:0];
                    tx_frame[4] <= last_loss[15:8];
                    tx_frame[5] <= {6'd0, after_hold || sw_sync[0], busy};
                    for (fi = 6; fi < 14; fi = fi + 1)
                        tx_frame[fi] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h74 ^ {3'd0, pred} ^ last_loss[7:0] ^ last_loss[15:8]
                        ^ {6'd0, after_hold || sw_sync[0], busy};
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                end else if (dump_z) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h75;
                    tx_frame[2] <= {2'd0, dump_i};
                    tx_frame[3] <= logits[dump_i[4:0]][7:0];
                    tx_frame[4] <= logits[dump_i[4:0]][15:8];
                    tx_frame[5] <= logits[dump_i[4:0]][23:16];
                    tx_frame[6] <= logits[dump_i[4:0]][31:24];
                    tx_frame[7] <= logits[dump_i[4:0] + 5'd1][7:0];
                    tx_frame[8] <= logits[dump_i[4:0] + 5'd1][15:8];
                    tx_frame[9] <= logits[dump_i[4:0] + 5'd1][23:16];
                    tx_frame[10] <= logits[dump_i[4:0] + 5'd1][31:24];
                    tx_frame[11] <= 8'd0;
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h75 ^ {2'd0, dump_i}
                        ^ logits[dump_i[4:0]][7:0] ^ logits[dump_i[4:0]][15:8]
                        ^ logits[dump_i[4:0]][23:16] ^ logits[dump_i[4:0]][31:24]
                        ^ logits[dump_i[4:0] + 5'd1][7:0] ^ logits[dump_i[4:0] + 5'd1][15:8]
                        ^ logits[dump_i[4:0] + 5'd1][23:16] ^ logits[dump_i[4:0] + 5'd1][31:24];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                    if (dump_i >= 6'd30)
                        dump_z <= 1'b0;
                    else
                        dump_i <= dump_i + 6'd2;
                end else if (dump_g) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h78;
                    tx_frame[2] <= {2'd0, dump_i};
                    tx_frame[3] <= gpack[{dump_i, 2'b00}][7:0];
                    tx_frame[4] <= gpack[{dump_i, 2'b00}][15:8];
                    tx_frame[5] <= gpack[{dump_i, 2'b01}][7:0];
                    tx_frame[6] <= gpack[{dump_i, 2'b01}][15:8];
                    tx_frame[7] <= gpack[{dump_i, 2'b10}][7:0];
                    tx_frame[8] <= gpack[{dump_i, 2'b10}][15:8];
                    tx_frame[9] <= gpack[{dump_i, 2'b11}][7:0];
                    tx_frame[10] <= gpack[{dump_i, 2'b11}][15:8];
                    tx_frame[11] <= 8'd0;
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h78 ^ {2'd0, dump_i}
                        ^ gpack[{dump_i, 2'b00}][7:0] ^ gpack[{dump_i, 2'b00}][15:8]
                        ^ gpack[{dump_i, 2'b01}][7:0] ^ gpack[{dump_i, 2'b01}][15:8]
                        ^ gpack[{dump_i, 2'b10}][7:0] ^ gpack[{dump_i, 2'b10}][15:8]
                        ^ gpack[{dump_i, 2'b11}][7:0] ^ gpack[{dump_i, 2'b11}][15:8];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                    if (dump_i >= 6'd31)
                        dump_g <= 1'b0;
                    else
                        dump_i <= dump_i + 6'd1;
                end else if (dump_c) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h7A;
                    tx_frame[2] <= wr_tok_n[7:0];
                    tx_frame[3] <= wr_tok_n[15:8];
                    tx_frame[4] <= wr_pos_n[7:0];
                    tx_frame[5] <= wr_pos_n[15:8];
                    tx_frame[6] <= wr_head_n[7:0];
                    tx_frame[7] <= wr_head_n[15:8];
                    tx_frame[8] <= wr_blk_n[7:0];
                    tx_frame[9] <= wr_blk_n[15:8];
                    tx_frame[10] <= last_loss[7:0];
                    tx_frame[11] <= last_loss[15:8];
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h7A
                        ^ wr_tok_n[7:0] ^ wr_tok_n[15:8]
                        ^ wr_pos_n[7:0] ^ wr_pos_n[15:8]
                        ^ wr_head_n[7:0] ^ wr_head_n[15:8]
                        ^ wr_blk_n[7:0] ^ wr_blk_n[15:8]
                        ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                    dump_c <= 1'b0;
                end else if (dump_h) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h76;
                    tx_frame[2] <= {5'd0, dump_i[2:0]};
                    tx_frame[3] <= dump_i[4:3];
                    tx_frame[4] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b00}][7:0];
                    tx_frame[5] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b00}][15:8];
                    tx_frame[6] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b01}][7:0];
                    tx_frame[7] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b01}][15:8];
                    tx_frame[8] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b10}][7:0];
                    tx_frame[9] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b10}][15:8];
                    tx_frame[10] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b11}][7:0];
                    tx_frame[11] <= y_reg[dump_i[2:0]][{dump_i[4:3], 2'b11}][15:8];
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h76 ^ {5'd0, dump_i[2:0]} ^ {6'd0, dump_i[4:3]}
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b00}][7:0]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b00}][15:8]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b01}][7:0]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b01}][15:8]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b10}][7:0]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b10}][15:8]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b11}][7:0]
                        ^ y_reg[dump_i[2:0]][{dump_i[4:3], 2'b11}][15:8];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                    if (dump_i >= 6'd31)
                        dump_h <= 1'b0;
                    else
                        dump_i <= dump_i + 6'd1;
                end else if (dump_a) begin
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h77;
                    tx_frame[2] <= {5'd0, dump_i[2:0]};
                    tx_frame[3] <= attn_w[dump_i[2:0]][0];
                    tx_frame[4] <= attn_w[dump_i[2:0]][1];
                    tx_frame[5] <= attn_w[dump_i[2:0]][2];
                    tx_frame[6] <= attn_w[dump_i[2:0]][3];
                    tx_frame[7] <= attn_w[dump_i[2:0]][4];
                    tx_frame[8] <= attn_w[dump_i[2:0]][5];
                    tx_frame[9] <= attn_w[dump_i[2:0]][6];
                    tx_frame[10] <= attn_w[dump_i[2:0]][7];
                    tx_frame[11] <= 8'd0;
                    tx_frame[12] <= 8'd0;
                    tx_frame[13] <= 8'd0;
                    xor14 = 8'hA5 ^ 8'h77 ^ {5'd0, dump_i[2:0]}
                        ^ attn_w[dump_i[2:0]][0] ^ attn_w[dump_i[2:0]][1]
                        ^ attn_w[dump_i[2:0]][2] ^ attn_w[dump_i[2:0]][3]
                        ^ attn_w[dump_i[2:0]][4] ^ attn_w[dump_i[2:0]][5]
                        ^ attn_w[dump_i[2:0]][6] ^ attn_w[dump_i[2:0]][7];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                    if (dump_i >= 6'd7)
                        dump_a <= 1'b0;
                    else
                        dump_i <= dump_i + 6'd1;
                end else if (send_mem) begin
                    send_mem <= 1'b0;
                    tx_frame[0] <= 8'hA5;
                    tx_frame[1] <= 8'h79;
                    tx_frame[2] <= {4'd0, rd_bank};
                    tx_frame[3] <= rd_addr[7:0];
                    tx_frame[4] <= {4'd0, rd_addr[11:8]};
                    tx_frame[5] <= 8'd8;
                    for (fi = 0; fi < 8; fi = fi + 1)
                        tx_frame[6 + fi] <= rd_bytes[fi];
                    xor14 = 8'hA5 ^ 8'h79 ^ {4'd0, rd_bank} ^ rd_addr[7:0]
                        ^ {4'd0, rd_addr[11:8]} ^ 8'd8
                        ^ rd_bytes[0] ^ rd_bytes[1] ^ rd_bytes[2] ^ rd_bytes[3]
                        ^ rd_bytes[4] ^ rd_bytes[5] ^ rd_bytes[6] ^ rd_bytes[7];
                    tx_frame[14] <= xor14;
                    tx_start <= 1'b1;
                end
            end
        end
    end

    always_comb begin
        led[0] = locked;
        led[1] = busy;
        led[2] = after_hold || sw_sync[0];
        led[3] = pred[0];
    end
endmodule
