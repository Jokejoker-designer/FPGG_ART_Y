`timescale 1ns/1ps
import a7lm04_pkg::*;

module tb_a7lm04_multitoken_diag;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic mem_we;
    logic [16:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic ctx_we;
    logic [4:0] ctx_idx, ctx_n_in;
    logic [7:0] ctx_bytes [0:7];
    logic [63:0] ctx_pack;
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [7:0] tgt_in;
    logic [3:0] lr_in;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [7:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;
    logic [7:0] wmem [0:100351];
    integer i;

    assign ctx_pack = {ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                       ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]};

    tiny_gpt100k_core u_core (
        .clk(clk), .rst_n(rst_n),
        .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n_in), .ctx_pack(ctx_pack),
        .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
        .start_corpus(start_corpus), .after_mode(after_mode),
        .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
        .tgt_in(tgt_in), .lr_in(lr_in), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
        .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
        .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32), .phase(phase)
    );

    initial begin
        mem_we = 1'b0; mem_addr = 17'd0; mem_wdata = 8'sd0;
        ctx_we = 1'b0; ctx_idx = 5'd0; ctx_n_in = 5'd0;
        start_fwd = 1'b0; start_train = 1'b0; start_ce = 1'b0; start_corpus = 1'b0;
        after_mode = 1'b1; do_snap = 1'b0; do_restore = 1'b0; do_fold = 1'b0;
        tgt_in = 8'd38; lr_in = 4'd3; corpus_n = 8'd8; corpus_ep = 8'd24;
        for (i = 0; i < 8; i = i + 1) ctx_bytes[i] = 8'd0;

        $readmemh("seed17_wmem.hex", wmem);
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        for (i = 0; i < NPARAM; i = i + 1) begin
            @(posedge clk);
            mem_we <= 1'b1;
            mem_addr <= i[16:0];
            mem_wdata <= wmem[i];
        end
        @(posedge clk);
        mem_we <= 1'b0;

        @(posedge clk);
        ctx_we <= 1'b1;
        ctx_idx <= 5'd0;
        ctx_n_in <= 5'd2;
        ctx_bytes[0] <= 8'd20;
        ctx_bytes[1] <= 8'd7;
        @(posedge clk);
        ctx_we <= 1'b0;

        @(posedge clk);
        start_fwd <= 1'b1;
        @(posedge clk);
        start_fwd <= 1'b0;

        fork
            begin wait (done); end
            begin
                repeat (30_000_000) @(posedge clk);
                $display("DIAG_TIMEOUT phase=%0d busy=%0d", phase, busy);
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);
        $display("DIAG_RESULT pred=%0d loss=%0d oracle_pred=140 oracle_loss=16 board_pred=26", pred, last_loss);
        if (pred !== 8'd140 || last_loss !== 16'd16) begin
            $display("DIAG_FAIL multi-token RTL/oracle mismatch");
            $finish;
        end
        $display("DIAG_PASS multi-token RTL matches oracle");
        $finish;
    end
endmodule
