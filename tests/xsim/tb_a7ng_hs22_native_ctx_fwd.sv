`timescale 1ns/1ps
import a7lm06_pkg::*;
//=============================================================================
// HS22-LM06-NATIVE-CTX-FWD-00  (R1 capture repair; same unknown)
// FPGA bind of sealed Native Top-8 IDs -> frozen tiny_gpt803k_core pred.
// R1: packet latched at accepted start; live gid[] poison after accept must not
//     change written ctx_pack or pred.
// R2: STRUCTURAL facts labelled separately from DYNAMIC counters.
// SIM_FULL=1 is an explicit zero-latency memory substitution (PREREGISTER).
//=============================================================================
module tb_a7ng_hs22_native_ctx_fwd;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic mem_we;
    logic [19:0] mem_addr;
    logic signed [7:0] mem_wdata, mem_rdata;
    logic ctx_we;
    logic [6:0] ctx_idx, ctx_n_in;
    logic [63:0] ctx_pack;
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
    logic w_stall;

    tiny_gpt803k_core #(.SIM_FULL(1'b1)) u_core (
        .clk(clk), .rst_n(rst_n),
        .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .ctx_we(ctx_we), .ctx_idx(ctx_idx), .ctx_n_in(ctx_n_in), .ctx_pack(ctx_pack),
        .start_fwd(start_fwd), .start_train(start_train), .start_ce(start_ce),
        .start_corpus(start_corpus), .after_mode(after_mode),
        .do_snap(do_snap), .do_restore(do_restore), .do_fold(do_fold),
        .tgt_in(tgt_in), .lr_in(lr_in), .corpus_n(corpus_n), .corpus_ep(corpus_ep),
        .busy(busy), .done(done), .pred(pred), .last_loss(last_loss),
        .ce0(ce0), .ce1(ce1), .wr_n(wr_n), .xor32(xor32), .add32(add32),
        .phase(phase), .w_stall(w_stall)
    );

    logic req_graph, req_lm;
    logic grant_graph, grant_lm;
    logic owner_is_graph, owner_is_lm, dual_owner_err;

    a7ng_lm_graph_arb u_arb (
        .clk(clk), .rst_n(rst_n),
        .req_graph_i(req_graph), .req_lm_i(req_lm),
        .grant_graph_o(grant_graph), .grant_lm_o(grant_lm),
        .owner_is_graph_o(owner_is_graph), .owner_is_lm_o(owner_is_lm),
        .dual_owner_err_o(dual_owner_err)
    );

    logic bind_start, bind_do_start;
    logic [31:0] gid [0:7];
    logic bind_busy, bind_done, capture_valid;
    logic [9:0] bind_pred;
    logic [31:0] bind_ctx_beats, bind_st_beats;

    a7ng_native_ctx_bind u_bind (
        .clk(clk), .rst_n(rst_n),
        .grant_lm_i(grant_lm),
        .start_i(bind_start),
        .do_start_i(bind_do_start),
        .global_id_i(gid),
        .core_busy_i(busy),
        .core_done_i(done),
        .core_pred_i(pred),
        .busy_o(bind_busy),
        .done_o(bind_done),
        .ctx_we_o(ctx_we),
        .ctx_idx_o(ctx_idx),
        .ctx_n_in_o(ctx_n_in),
        .ctx_pack_o(ctx_pack),
        .start_fwd_o(start_fwd),
        .pred_o(bind_pred),
        .ctx_we_beats_o(bind_ctx_beats),
        .start_fwd_beats_o(bind_st_beats),
        .capture_valid_o(capture_valid)
    );

    // DYNAMIC counters only.
    int unsigned mem_we_exam = 0;
    int unsigned dual_owner_ticks = 0;
    int unsigned capture_mismatch = 0;
    bit exam;

    always_ff @(posedge clk) begin
        if (rst_n && exam && mem_we)
            mem_we_exam <= mem_we_exam + 1;
        if (rst_n && dual_owner_err)
            dual_owner_ticks <= dual_owner_ticks + 1;
    end

    function automatic logic [63:0] pack_ids(input logic [31:0] a [0:7]);
        integer k;
        pack_ids = 64'd0;
        for (k = 0; k < 8; k = k + 1)
            pack_ids[8*k +: 8] = a[k][7:0];
    endfunction

    logic [7:0] wmem [0:802815];
    integer i;
    logic [9:0] pred_reset, pred_neg, pred_e0, pred_e1;
    bit done_e0, done_e1, neg_stable, capture_e0_ok, capture_e1_ok;
    logic [63:0] expect_e0, expect_e1, seen_pack;
    logic [31:0] e0_ids [0:7];
    logic [31:0] e1_ids [0:7];

    task automatic load_e0;
        gid[0] = 32'd9;  gid[1] = 32'd11; gid[2] = 32'd25; gid[3] = 32'd27;
        gid[4] = 32'd41; gid[5] = 32'd43; gid[6] = 32'd57; gid[7] = 32'd59;
    endtask

    task automatic load_e1;
        gid[0] = 32'd59; gid[1] = 32'd11; gid[2] = 32'd25; gid[3] = 32'd27;
        gid[4] = 32'd41; gid[5] = 32'd43; gid[6] = 32'd57; gid[7] = 32'd9;
    endtask

    task automatic poison_gid;
        integer k;
        for (k = 0; k < 8; k = k + 1)
            gid[k] = 32'd255;
    endtask

    task automatic wait_bind_done(input integer to_cyc, input string tag);
        fork
            begin
                wait (bind_done);
            end
            begin
                repeat (to_cyc) @(posedge clk);
                $display("FAIL timeout %s phase=%0d busy=%0d", tag, phase, busy);
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk);
    endtask

    // R2: poison on the negedge strictly between accept posedge and S_CTX write posedge.
    task automatic pulse_bind_poison(input bit do_st, input logic [63:0] expect_pack, output bit cap_ok);
        @(posedge clk);
        bind_do_start <= do_st;
        bind_start    <= 1'b1;
        @(posedge clk);
        bind_start    <= 1'b0;
        @(negedge clk);
        poison_gid();
        $display("R2_POISON_NEGEDGE between_accept_and_S_CTX");
        @(posedge clk);
        #1;
        if (ctx_we !== 1'b1) begin
            $display("FAIL no ctx_we on S_CTX posedge after negedge poison");
            $finish;
        end
        seen_pack = ctx_pack;
        cap_ok = (ctx_pack === expect_pack) && capture_valid;
        if (!cap_ok) begin
            capture_mismatch = capture_mismatch + 1;
            $display("FAIL CAPTURE live-bus poison wrote %h expected %h", ctx_pack, expect_pack);
            $finish;
        end
        $display("CAPTURE_OK pack=%h after_poison_gid=255 ctx_we=1", ctx_pack);
    endtask

    initial begin
        mem_we = 1'b0; mem_addr = 20'd0; mem_wdata = 8'sd0;
        start_train = 1'b0; start_ce = 1'b0; start_corpus = 1'b0;
        after_mode = 1'b0; do_snap = 1'b0; do_restore = 1'b0; do_fold = 1'b0;
        tgt_in = 10'd0; lr_in = 4'd0; corpus_n = 8'd0; corpus_ep = 8'd0;
        req_graph = 1'b0; req_lm = 1'b0;
        bind_start = 1'b0; bind_do_start = 1'b0;
        exam = 1'b0;
        capture_e0_ok = 1'b0;
        capture_e1_ok = 1'b0;
        load_e0();
        e0_ids[0] = 32'd9;  e0_ids[1] = 32'd11; e0_ids[2] = 32'd25; e0_ids[3] = 32'd27;
        e0_ids[4] = 32'd41; e0_ids[5] = 32'd43; e0_ids[6] = 32'd57; e0_ids[7] = 32'd59;
        e1_ids[0] = 32'd59; e1_ids[1] = 32'd11; e1_ids[2] = 32'd25; e1_ids[3] = 32'd27;
        e1_ids[4] = 32'd41; e1_ids[5] = 32'd43; e1_ids[6] = 32'd57; e1_ids[7] = 32'd9;
        expect_e0 = pack_ids(e0_ids);
        expect_e1 = pack_ids(e1_ids);

        $readmemh("a7lm06_wmem.hex", wmem);

        $display("STRUCTURAL DUT_HIER core=%m.u_core bind=%m.u_bind arb=%m.u_arb");
        $display("STRUCTURAL SOURCE tiny_gpt803k_core=1 a7ng_native_ctx_bind=1 a7ng_lm_graph_arb=1 uart_module=0");
        $display("STRUCTURAL NO_UART_NO_HOST_CTX_DRIVER compile_list has no UART decoder");

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);
        pred_reset = pred;

        for (i = 0; i < NPARAM; i = i + 1) begin
            @(posedge clk);
            mem_we    <= 1'b1;
            mem_addr  <= i[19:0];
            mem_wdata <= wmem[i];
        end
        @(posedge clk);
        mem_we   <= 1'b0;
        mem_addr <= 20'd0;
        repeat (8) @(posedge clk);

        exam = 1'b1;
        req_lm = 1'b1;
        @(posedge clk);
        wait (grant_lm);
        @(posedge clk);

        // Negative control: E0 into tok[], no start_fwd (still capture+poison)
        load_e0();
        pulse_bind_poison(1'b0, expect_e0, capture_e0_ok);
        wait_bind_done(1024, "NEG_CTX");
        pred_neg = pred;
        repeat (256) @(posedge clk);
        neg_stable = (pred === pred_neg) && (pred === pred_reset);
        if (!neg_stable) begin
            $display("FAIL neg_pred_stable reset=%0d neg=%0d now=%0d",
                     pred_reset, pred_neg, pred);
            $finish;
        end
        if (bind_st_beats !== 32'd0) begin
            $display("FAIL neg start_fwd_beats=%0d", bind_st_beats);
            $finish;
        end
        $display("NEG_OK pred=%0d ctx_beats=%0d start_beats=%0d",
                 pred_neg, bind_ctx_beats, bind_st_beats);

        // E0 forward + R1 adversarial poison after accept
        load_e0();
        pulse_bind_poison(1'b1, expect_e0, capture_e0_ok);
        wait_bind_done(200_000_000, "E0");
        pred_e0 = bind_pred;
        done_e0 = 1'b1;
        $display("E0_DONE pred=%0d phase=%0d start_beats=%0d capture_ok=%0d",
                 pred_e0, phase, bind_st_beats, capture_e0_ok);

        // E1 forward + poison
        load_e1();
        pulse_bind_poison(1'b1, expect_e1, capture_e1_ok);
        wait_bind_done(200_000_000, "E1");
        pred_e1 = bind_pred;
        done_e1 = 1'b1;
        $display("E1_DONE pred=%0d phase=%0d start_beats=%0d capture_ok=%0d",
                 pred_e1, phase, bind_st_beats, capture_e1_ok);

        $display("HS22_DYNAMIC ctx_we_beats=%0d start_fwd_beats=%0d pred_E0=%0d pred_E1=%0d done_E0=%0d done_E1=%0d grant_lm=%0d dual_owner_ticks=%0d mem_we_exam=%0d neg_stable=%0d capture_mismatch=%0d capture_e0=%0d capture_e1=%0d",
                 bind_ctx_beats, bind_st_beats, pred_e0, pred_e1, done_e0, done_e1,
                 grant_lm, dual_owner_ticks, mem_we_exam, neg_stable,
                 capture_mismatch, capture_e0_ok, capture_e1_ok);

        if (dual_owner_ticks !== 0) begin
            $display("FAIL dual_owner_ticks=%0d", dual_owner_ticks);
            $finish;
        end
        if (bind_ctx_beats < 32'd2) begin
            $display("FAIL ctx_we_beats=%0d", bind_ctx_beats);
            $finish;
        end
        if (bind_st_beats !== 32'd2) begin
            $display("FAIL start_fwd_beats=%0d", bind_st_beats);
            $finish;
        end
        if (mem_we_exam !== 0) begin
            $display("FAIL mem_we_exam=%0d", mem_we_exam);
            $finish;
        end
        if (start_train !== 1'b0 || start_corpus !== 1'b0) begin
            $display("FAIL train/corpus");
            $finish;
        end
        if (!capture_e0_ok || !capture_e1_ok || capture_mismatch !== 0) begin
            $display("FAIL capture");
            $finish;
        end
        if (pred_e0 === pred_e1) begin
            $display("FAIL pred invariant E0=E1=%0d", pred_e0);
            $finish;
        end
        $display("HS22_LM06_NATIVE_CTX_FWD_XSIM_PASS pred_E0=%0d pred_E1=%0d SIM_FULL=1 R1_CAPTURE=1", pred_e0, pred_e1);
        $finish;
    end
endmodule
