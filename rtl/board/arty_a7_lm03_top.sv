`timescale 1ns/1ps
// A7-LM-03: 25K 2-layer/2-head. No DDR. Does not overwrite LM-00/01/02 bits.
module arty_a7_lm03_top (
    input  logic CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic uart_rxd_out,
    input  logic uart_txd_in
);
    logic rst_n, btn0_s, clk50;
    logic [3:0] sw_s;
    logic rx_valid;
    logic [7:0] rx_data;
    logic collecting;
    logic [3:0] idx;
    logic [7:0] buf_b [0:14];
    logic [7:0] run_xor;
    logic mem_we, ctx_we;
    logic [14:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic [3:0] ctx_idx, ctx_n;
    logic [7:0] ctx_bytes [0:7];
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [6:0] tgt;
    logic [3:0] lr;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [6:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;
    logic tx_start, tx_busy;
    logic [7:0] tx_frame [0:14];
    logic cmd_stat, cmd_ce, cmd_pred;
    logic pend_a2;
    logic rd_go, rd_pend;
    logic [2:0] rd_i, rd_wait;
    logic [14:0] rd_base;
    logic [7:0] rd_bytes [0:7];
    integer fi;

    sync_bits #(.WIDTH(1)) u_b0 (.clk(CLK100MHZ), .rst_n(1'b1), .async_in(btn[0]), .sync_out(btn0_s));
    assign rst_n = !btn0_s;
    clkdiv2 u_div (.clk_in(CLK100MHZ), .rst_n(rst_n), .clk_out(clk50));
    sync_bits #(.WIDTH(4)) u_sw (.clk(clk50), .rst_n(rst_n), .async_in(sw), .sync_out(sw_s));

    uart_rx #(.CLK_HZ(50000000), .BAUD(115200)) u_rx (
        .clk(clk50), .rst_n(rst_n), .rx(uart_txd_in), .data(rx_data), .valid(rx_valid)
    );
    lm02_tx #(.CLK_HZ(50000000), .BAUD(115200)) u_tx (
        .clk(clk50), .rst_n(rst_n), .start(tx_start), .frame(tx_frame),
        .tx(uart_rxd_out), .busy(tx_busy)
    );

    tiny_gpt25k_core u_core (
        .clk(clk50), .rst_n(rst_n),
        .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n),
        .ctx_pack({ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                   ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]}),
        .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
        .start_corpus(start_corpus), .after_mode(after_mode || sw_s[0]),
        .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
        .tgt_in(tgt), .lr_in(lr), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
        .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
        .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32), .phase(phase)
    );

    always_ff @(posedge clk50) begin
        if (!rst_n) begin
            collecting <= 1'b0;
            idx <= 4'd0;
            run_xor <= 8'd0;
            mem_we <= 1'b0;
            ctx_we <= 1'b0;
            start_fwd <= 1'b0;
            start_train <= 1'b0;
            start_ce <= 1'b0;
            start_corpus <= 1'b0;
            do_snap <= 1'b0;
            do_restore <= 1'b0;
            do_fold <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_ce <= 1'b0;
            cmd_pred <= 1'b0;
            pend_a2 <= 1'b0;
            rd_go <= 1'b0;
            rd_pend <= 1'b0;
            rd_i <= 3'd0;
            rd_wait <= 3'd0;
            rd_base <= 15'd0;
            tx_start <= 1'b0;
            after_mode <= 1'b0;
            tgt <= 7'd0;
            lr <= 4'd3;
            corpus_n <= 8'd8;
            corpus_ep <= 8'd24;
            mem_addr <= 15'd0;
        end else begin
            mem_we <= 1'b0;
            ctx_we <= 1'b0;
            start_fwd <= 1'b0;
            start_train <= 1'b0;
            start_ce <= 1'b0;
            start_corpus <= 1'b0;
            do_snap <= 1'b0;
            do_restore <= 1'b0;
            do_fold <= 1'b0;
            cmd_stat <= 1'b0;
            cmd_ce <= 1'b0;
            cmd_pred <= 1'b0;
            tx_start <= 1'b0;
            if (rx_valid) begin
                if (!collecting) begin
                    if (rx_data == 8'hA5) begin
                        collecting <= 1'b1;
                        idx <= 4'd1;
                        buf_b[0] <= 8'hA5;
                        run_xor <= 8'hA5;
                    end
                end else begin
                    buf_b[idx] <= rx_data;
                    if (idx < 4'd14) run_xor <= run_xor ^ rx_data;
                    if (idx == 4'd14) begin
                        collecting <= 1'b0;
                        idx <= 4'd0;
                        if ((run_xor ^ rx_data) == 8'd0 && buf_b[1] == 8'h73) begin
                            unique case (buf_b[2])
                                8'h30: begin
                                    mem_we <= 1'b1;
                                    mem_addr <= {buf_b[4][6:0], buf_b[3]};
                                    mem_wdata <= buf_b[5];
                                end
                                8'h31: begin
                                    // Read-only: 8 consecutive bytes, BRAM latency handled below.
                                    mem_addr <= {buf_b[4][6:0], buf_b[3]};
                                    rd_base <= {buf_b[4][6:0], buf_b[3]};
                                    rd_i <= 3'd0;
                                    rd_wait <= 3'd0;
                                    rd_go <= 1'b1;
                                    rd_pend <= 1'b0;
                                end
                                8'h32: begin
                                    ctx_we <= 1'b1;
                                    ctx_idx <= buf_b[3][3:0];
                                    ctx_n <= buf_b[4][3:0];
                                    ctx_bytes[0] <= buf_b[5];
                                    ctx_bytes[1] <= buf_b[6];
                                    ctx_bytes[2] <= buf_b[7];
                                    ctx_bytes[3] <= buf_b[8];
                                    ctx_bytes[4] <= buf_b[9];
                                    ctx_bytes[5] <= buf_b[10];
                                    ctx_bytes[6] <= buf_b[11];
                                    ctx_bytes[7] <= buf_b[12];
                                end
                                8'h33: start_fwd <= 1'b1;
                                8'h34: begin
                                    tgt <= buf_b[3][6:0];
                                    lr <= buf_b[4][3:0];
                                    start_train <= 1'b1;
                                end
                                8'h35: cmd_stat <= 1'b1;
                                8'h36: do_fold <= 1'b1;
                                8'h37: cmd_ce <= 1'b1;
                                8'h38: after_mode <= buf_b[3][0];
                                8'h39: if (buf_b[3][0]) do_restore <= 1'b1; else do_snap <= 1'b1;
                                8'h3A: begin
                                    corpus_n <= buf_b[3];
                                    corpus_ep <= buf_b[4];
                                    lr <= buf_b[5][3:0];
                                    start_corpus <= 1'b1;
                                end
                                8'h3B: cmd_pred <= 1'b1;
                                8'h3C: start_ce <= 1'b1;
                                default: ;
                            endcase
                        end
                    end else
                        idx <= idx + 4'd1;
                end
            end
            if (done)
                pend_a2 <= 1'b1;
            // 0x31 readback: present mem_addr, wait 3 clk (addr settle + BRAM + 1),
            // capture mem_rdata, then 0xA4. Only while core is idle.
            if (rd_go && !busy) begin
                mem_addr <= rd_base + {12'd0, rd_i};
                if (rd_wait < 3'd3)
                    rd_wait <= rd_wait + 3'd1;
                else begin
                    rd_bytes[rd_i] <= mem_rdata;
                    rd_wait <= 3'd0;
                    if (rd_i == 3'd7) begin
                        rd_go <= 1'b0;
                        rd_pend <= 1'b1;
                    end else
                        rd_i <= rd_i + 3'd1;
                end
            end
            if (!tx_busy && !tx_start) begin
                if (cmd_stat) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA1;
                    tx_frame[2] <= {after_mode, busy, done, 5'd0};
                    tx_frame[3] <= phase;
                    tx_frame[4] <= wr_n[7:0]; tx_frame[5] <= wr_n[15:8];
                    tx_frame[6] <= wr_n[23:16]; tx_frame[7] <= wr_n[31:24];
                    tx_frame[8] <= pred; tx_frame[9] <= last_loss[7:0];
                    tx_frame[10] <= last_loss[15:8];
                    for (fi = 11; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA1 ^ {after_mode, busy, done, 5'd0} ^ phase
                        ^ wr_n[7:0] ^ wr_n[15:8] ^ wr_n[23:16] ^ wr_n[31:24]
                        ^ pred ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end else if (pend_a2) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA2;
                    tx_frame[2] <= xor32[7:0]; tx_frame[3] <= xor32[15:8];
                    tx_frame[4] <= xor32[23:16]; tx_frame[5] <= xor32[31:24];
                    tx_frame[6] <= add32[7:0]; tx_frame[7] <= add32[15:8];
                    tx_frame[8] <= add32[23:16]; tx_frame[9] <= add32[31:24];
                    tx_frame[10] <= wr_n[7:0]; tx_frame[11] <= wr_n[15:8];
                    tx_frame[12] <= wr_n[23:16]; tx_frame[13] <= wr_n[31:24];
                    tx_frame[14] <= 8'hA5 ^ 8'hA2
                        ^ xor32[7:0] ^ xor32[15:8] ^ xor32[23:16] ^ xor32[31:24]
                        ^ add32[7:0] ^ add32[15:8] ^ add32[23:16] ^ add32[31:24]
                        ^ wr_n[7:0] ^ wr_n[15:8] ^ wr_n[23:16] ^ wr_n[31:24];
                    tx_start <= 1'b1;
                    pend_a2 <= 1'b0;
                end else if (cmd_ce) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA3;
                    tx_frame[2] <= ce0[7:0]; tx_frame[3] <= ce0[15:8];
                    tx_frame[4] <= ce0[23:16]; tx_frame[5] <= ce0[31:24];
                    tx_frame[6] <= ce1[7:0]; tx_frame[7] <= ce1[15:8];
                    tx_frame[8] <= ce1[23:16]; tx_frame[9] <= ce1[31:24];
                    tx_frame[10] <= last_loss[7:0]; tx_frame[11] <= last_loss[15:8];
                    tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA3
                        ^ ce0[7:0] ^ ce0[15:8] ^ ce0[23:16] ^ ce0[31:24]
                        ^ ce1[7:0] ^ ce1[15:8] ^ ce1[23:16] ^ ce1[31:24]
                        ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end else if (rd_pend) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA4;
                    tx_frame[2] <= rd_base[7:0];
                    tx_frame[3] <= {1'b0, rd_base[14:8]};
                    tx_frame[4] <= rd_bytes[0]; tx_frame[5] <= rd_bytes[1];
                    tx_frame[6] <= rd_bytes[2]; tx_frame[7] <= rd_bytes[3];
                    tx_frame[8] <= rd_bytes[4]; tx_frame[9] <= rd_bytes[5];
                    tx_frame[10] <= rd_bytes[6]; tx_frame[11] <= rd_bytes[7];
                    tx_frame[12] <= 8'd0; tx_frame[13] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA4
                        ^ rd_base[7:0] ^ {1'b0, rd_base[14:8]}
                        ^ rd_bytes[0] ^ rd_bytes[1] ^ rd_bytes[2] ^ rd_bytes[3]
                        ^ rd_bytes[4] ^ rd_bytes[5] ^ rd_bytes[6] ^ rd_bytes[7];
                    tx_start <= 1'b1;
                    rd_pend <= 1'b0;
                end else if (cmd_pred) begin
                    tx_frame[0] <= 8'hA5; tx_frame[1] <= 8'hA0;
                    tx_frame[2] <= {1'b0, pred};
                    tx_frame[3] <= last_loss[7:0];
                    tx_frame[4] <= last_loss[15:8];
                    for (fi = 5; fi < 14; fi = fi + 1) tx_frame[fi] <= 8'd0;
                    tx_frame[14] <= 8'hA5 ^ 8'hA0 ^ {1'b0, pred}
                        ^ last_loss[7:0] ^ last_loss[15:8];
                    tx_start <= 1'b1;
                end
            end
        end
    end

    assign led[0] = !busy;
    assign led[1] = busy;
    assign led[2] = (ce0 != 0) && (ce1 < ce0);
    assign led[3] = after_mode || sw_s[0];
endmodule
