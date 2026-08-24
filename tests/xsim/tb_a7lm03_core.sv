`timescale 1ns/1ps
import a7lm03_pkg::*;
// Behavioral smoke: upload seed-2 weights, forward [1], check pred/loss vs golden.
module tb_a7lm03_core;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic mem_we;
    logic [14:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic ctx_we;
    logic [3:0] ctx_idx, ctx_n_in;
    logic [7:0] ctx_bytes [0:7];
    logic [63:0] ctx_pack;
    assign ctx_pack = {ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                       ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]};
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [6:0] tgt_in;
    logic [3:0] lr_in;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [6:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;

    tiny_gpt25k_core u_core (
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

    logic [7:0] wmem [0:25087];
    integer i, exp_pred, exp_loss, exp_xor, exp_add, exp_xor1, exp_add1, fd;
    string line;

    initial begin
        mem_we = 1'b0; mem_addr = 15'd0; mem_wdata = 8'sd0;
        ctx_we = 1'b0; ctx_idx = 4'd0; ctx_n_in = 4'd0;
        start_fwd = 1'b0; start_train = 1'b0; start_ce = 1'b0; start_corpus = 1'b0;
        after_mode = 1'b0; do_snap = 1'b0; do_restore = 1'b0; do_fold = 1'b0;
        tgt_in = 7'd16; lr_in = 4'd3; corpus_n = 8'd8; corpus_ep = 8'd24;
        for (i = 0; i < 8; i = i + 1) ctx_bytes[i] = 8'd0;

        $readmemh("a7lm03_wmem.hex", wmem);
        fd = $fopen("a7lm03_expected.txt", "r");
        if (fd == 0) begin
            $display("FAIL missing a7lm03_expected.txt");
            $finish;
        end
        void'($fscanf(fd, "%d\n%d\n%d\n%d\n%d\n%d\n",
            exp_pred, exp_loss, exp_xor, exp_add, exp_xor1, exp_add1));
        $fclose(fd);

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        for (i = 0; i < NPARAM; i = i + 1) begin
            @(posedge clk);
            mem_we <= 1'b1;
            mem_addr <= i[14:0];
            mem_wdata <= wmem[i];
        end
        @(posedge clk);
        mem_we <= 1'b0;

        // Host readback path: idle + mem_addr, 1-cycle BRAM + margin.
        @(posedge clk);
        mem_addr <= 15'd0;
        repeat (4) @(posedge clk);
        if (mem_rdata !== wmem[0]) begin
            $display("FAIL readback0 got=%0d exp=%0d", mem_rdata, wmem[0]);
            $finish;
        end
        mem_addr <= 15'd1;
        repeat (4) @(posedge clk);
        if (mem_rdata !== wmem[1]) begin
            $display("FAIL readback1 got=%0d exp=%0d", mem_rdata, wmem[1]);
            $finish;
        end
        $display("READBACK ok w0=%0d w1=%0d", wmem[0], wmem[1]);

        @(posedge clk);
        ctx_we <= 1'b1;
        ctx_idx <= 4'd0;
        ctx_n_in <= 4'd1;
        ctx_bytes[0] <= 8'd1;
        @(posedge clk);
        ctx_we <= 1'b0;

        @(posedge clk);
        start_fwd <= 1'b1;
        tgt_in <= 7'd16;
        @(posedge clk);
        start_fwd <= 1'b0;

        fork
            begin
                wait (done);
            end
            begin
                repeat (5_000_000) @(posedge clk);
                $display("FAIL timeout phase=%0d busy=%0d", phase, busy);
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);

`ifndef A7LM03_NETLIST
        $display("DBG ntok=%0d st=%0d ly=%0d ten_o=%0d row=%0d dim=%0d sub=%0d",
            u_core.ntok, u_core.st, u_core.ly, u_core.ten_o, u_core.row, u_core.dim, u_core.sub);
        $display("DBG wmem0=%0d wmem1=%0d wmem_last=%0d", wmem[0], wmem[1], wmem[25087]);
        $display("DBG logit0=%0d logit1=%0d logit123=%0d logit127=%0d",
            u_core.logits[0], u_core.logits[1], u_core.logits[123], u_core.logits[127]);
        $display("DBG mx=%0d ssoft=%0d smx0=%0d smx16=%0d",
            u_core.mx, u_core.ssoft, u_core.smx_e[0], u_core.smx_e[16]);
`endif
        $display("FWD pred=%0d exp=%0d loss=%0d exp=%0d", pred, exp_pred, last_loss, exp_loss);
        if (pred !== exp_pred[6:0] || last_loss !== exp_loss[15:0]) begin
            $display("FAIL forward mismatch");
            $finish;
        end

        @(posedge clk);
        do_fold <= 1'b1;
        @(posedge clk);
        do_fold <= 1'b0;
        fork
            begin
                wait (done);
            end
            begin
                repeat (2_000_000) @(posedge clk);
                $display("FAIL fold timeout");
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);
        $display("FOLD xor=%0d exp=%0d add=%0d exp=%0d", xor32, exp_xor, add32, exp_add);
        if (xor32 !== exp_xor || add32 !== exp_add) begin
            $display("FAIL fold mismatch");
            $finish;
        end

        @(posedge clk);
        ctx_we <= 1'b1;
        ctx_idx <= 4'd0;
        ctx_n_in <= 4'd1;
        ctx_bytes[0] <= 8'd1;
        @(posedge clk);
        ctx_we <= 1'b0;
        @(posedge clk);
        start_train <= 1'b1;
        tgt_in <= 7'd16;
        lr_in <= 4'd3;
        @(posedge clk);
        start_train <= 1'b0;
        fork
            begin
                wait (done);
            end
            begin
                repeat (8_000_000) @(posedge clk);
                $display("FAIL train timeout phase=%0d", phase);
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);
        do_fold <= 1'b1;
        @(posedge clk);
        do_fold <= 1'b0;
        fork
            begin
                wait (done);
            end
            begin
                repeat (2_000_000) @(posedge clk);
                $display("FAIL fold1 timeout");
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);
        $display("FOLD1 xor=%0d exp=%0d add=%0d exp=%0d wr=%0d", xor32, exp_xor1, add32, exp_add1, wr_n);
`ifndef A7LM03_NETLIST
        begin
            integer df;
            df = $fopen("hw_after_full.txt", "w");
            for (i = 0; i < NPARAM; i = i + 1)
                $fdisplay(df, "%0d", $signed(u_core.u_w.mem[i]));
            $fclose(df);
        end
`endif
        if (xor32 !== exp_xor1 || add32 !== exp_add1) begin
            $display("FAIL fold after full step");
            $finish;
        end
        $display("A7LM03_XSIM_PASS pred=%0d loss=%0d wr_n=%0d", pred, last_loss, wr_n);
        $finish;
    end
endmodule
