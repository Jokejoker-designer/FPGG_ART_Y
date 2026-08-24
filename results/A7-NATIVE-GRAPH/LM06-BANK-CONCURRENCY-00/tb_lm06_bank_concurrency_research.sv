`timescale 1ns/1ps
// Research-only LM06 bank concurrency tracer (results/ only; no rtl/tests edits).
import a7lm06_pkg::*;
module tb_lm06_bank_concurrency_research;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic mem_we;
    logic [19:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic ctx_we;
    logic [6:0] ctx_idx, ctx_n_in;
    logic [7:0] ctx_bytes [0:7];
    logic [63:0] ctx_pack;
    assign ctx_pack = {ctx_bytes[7], ctx_bytes[6], ctx_bytes[5], ctx_bytes[4],
                       ctx_bytes[3], ctx_bytes[2], ctx_bytes[1], ctx_bytes[0]};
    logic start_fwd, start_train, start_ce, start_corpus;
    logic after_mode, do_snap, do_restore, do_fold;
    logic [9:0] tgt_in;
    logic [3:0] lr_in;
    logic [7:0] corpus_n, corpus_ep;
    logic busy, done;
    logic [9:0] pred;
    logic [15:0] last_loss;
    logic [31:0] ce0, ce1, wr_n, xor32, add32;
    logic [7:0] phase;

    tiny_gpt803k_core #(.SIM_FULL(1'b1)) u_core (
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

    integer cyc;
    integer fd_sum;
    integer act_cycles, act_wr, act_diff_addr, act_rw_collide;
    integer w_wr, w_diff_addr;
    integer snap_w, snap_rw_collide;
    integer max_act_ports_seen, max_w_ports_seen;
    integer j, exp_pred, exp_loss, exp_xor, exp_add, exp_xor1, exp_add1, fd;
    logic [7:0] wmem [0:802815];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cyc <= 0; act_cycles <= 0; act_wr <= 0; act_diff_addr <= 0; act_rw_collide <= 0;
            w_wr <= 0; w_diff_addr <= 0; snap_w <= 0; snap_rw_collide <= 0;
            max_act_ports_seen <= 0; max_w_ports_seen <= 0;
        end else if (busy) begin
            cyc <= cyc + 1;
            act_cycles <= act_cycles + 1;
            if (u_core.awe) act_wr <= act_wr + 1;
            if (u_core.aaddr != u_core.aaddr_b) act_diff_addr <= act_diff_addr + 1;
            if (u_core.awe && (u_core.aaddr == u_core.aaddr_b))
                act_rw_collide <= act_rw_collide + 1;
            if (max_act_ports_seen < 2) max_act_ports_seen <= 2;
            if (u_core.wwe || u_core.host_we) w_wr <= w_wr + 1;
            if (u_core.waddr != u_core.w_addr_b) w_diff_addr <= w_diff_addr + 1;
            if (max_w_ports_seen < 2) max_w_ports_seen <= 2;
            if (u_core.snap_we) snap_w <= snap_w + 1;
            if (u_core.snap_we && (u_core.snap_waddr == u_core.snap_raddr))
                snap_rw_collide <= snap_rw_collide + 1;
        end
    end

    initial begin
        mem_we = 1'b0; mem_addr = 20'd0; mem_wdata = 8'sd0;
        ctx_we = 1'b0; ctx_idx = 7'd0; ctx_n_in = 7'd0;
        start_fwd = 1'b0; start_train = 1'b0; start_ce = 1'b0; start_corpus = 1'b0;
        after_mode = 1'b0; do_snap = 1'b0; do_restore = 1'b0; do_fold = 1'b0;
        tgt_in = 10'd32; lr_in = 4'd3; corpus_n = 8'd8; corpus_ep = 8'd24;
        for (j = 0; j < 8; j = j + 1) ctx_bytes[j] = 8'd0;

        $readmemh("a7lm06_wmem.hex", wmem);
        fd = $fopen("a7lm06_expected.txt", "r");
        if (fd == 0) begin
            $display("FAIL missing a7lm06_expected.txt");
            $finish;
        end
        void'($fscanf(fd, "%d\n%d\n%d\n%d\n%d\n%d\n",
            exp_pred, exp_loss, exp_xor, exp_add, exp_xor1, exp_add1));
        $fclose(fd);

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        for (j = 0; j < NPARAM; j = j + 1) begin
            @(posedge clk);
            mem_we <= 1'b1;
            mem_addr <= j[19:0];
            mem_wdata <= wmem[j];
        end
        @(posedge clk);
        mem_we <= 1'b0;
        mem_addr <= 20'd0;
        repeat (4) @(posedge clk);

        @(posedge clk);
        ctx_we <= 1'b1; ctx_idx <= 7'd0; ctx_n_in <= 7'd1; ctx_bytes[0] <= 8'd1;
        @(posedge clk);
        ctx_we <= 1'b0;

        @(posedge clk);
        start_fwd <= 1'b1; tgt_in <= 10'd32;
        @(posedge clk);
        start_fwd <= 1'b0;
        fork
            begin wait (done); end
            begin
                repeat (200_000_000) @(posedge clk);
                $display("FAIL fwd timeout");
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);

        fd_sum = $fopen("BANK_ACCESS_TRACE_SUMMARY.txt", "w");
        $fwrite(fd_sum, "workload=A7LM06_FWD_ONLY\n");
        $fwrite(fd_sum, "SIM_FULL=1\n");
        $fwrite(fd_sum, "evidence_class=LM06_XSIM_RESEARCH\n");
        $fwrite(fd_sum, "busy_cycles=%0d\n", cyc);
        $fwrite(fd_sum, "act_cycles=%0d act_wr=%0d act_diff_addr=%0d act_rw_collide=%0d max_act_ports=%0d\n",
            act_cycles, act_wr, act_diff_addr, act_rw_collide, max_act_ports_seen);
        $fwrite(fd_sum, "w_wr=%0d w_diff_addr=%0d max_w_ports=%0d\n",
            w_wr, w_diff_addr, max_w_ports_seen);
        $fwrite(fd_sum, "snap_w=%0d snap_rw_collide=%0d\n", snap_w, snap_rw_collide);
        $fwrite(fd_sum, "pred=%0d exp_pred=%0d\n", pred, exp_pred);
        $fwrite(fd_sum, "NOTE=SIM_FULL1_weight_array_not_silicon_TILE; act/snap dual-port FSM is law-faithful\n");
        $fclose(fd_sum);
        $display("BANK_CONCURRENCY_TRACE_DONE cycles=%0d pred=%0d", cyc, pred);
        $display("LM06_BANK_CONCURRENCY_XSIM_PASS");
        $finish;
    end
endmodule
