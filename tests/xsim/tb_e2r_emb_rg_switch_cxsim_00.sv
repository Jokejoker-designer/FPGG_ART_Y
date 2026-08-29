`timescale 1ns / 1ps
import a7lm06_pkg::*;
// E2R-EMB-RG-SWITCH-CXSIM-00 — ST_EMB TOK vs POS waddr set count.
// Instantiates tiny_gpt803k_core #(.SIM_FULL(1)) only. No SoC. No MIG.
// Do not edit rtl/**. PROGRAM=NO. C_FIX=NONE.
module tb_e2r_emb_rg_switch_cxsim_00;
  logic clk;
  logic rst_n;
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

  localparam int TIMEOUT_CLK = 100000;
  localparam int EXPECT_SETS = 8 * D;

  function automatic bit is_tok_rg(input logic [19:0] a);
    return (a < 20'(OFF_POS));
  endfunction

  function automatic bit is_pos_rg(input logic [19:0] a);
    return (a >= 20'(OFF_POS)) && (a < 20'(OFF_L0));
  endfunction

  function automatic int rg_id(input logic [19:0] a);
    if (is_tok_rg(a)) return 0;
    if (is_pos_rg(a)) return 1;
    return 2;
  endfunction

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    int cyc;
    int tok_sets;
    int pos_sets;
    int rg_switches;
    int emb_cycles;
    bit entered_emb;
    bit leave_emb;
    bit timed_out;
    bit classified;
    string verdict;
    logic [5:0] st_now;
    logic [5:0] st_prev;
    logic [19:0] waddr_now;
    logic [19:0] waddr_prev;
    logic [3:0] sub_now;
    logic [3:0] sub_prev;
    int rg_now;
    int rg_prev;
    int ntok_h;

    clk = 1'b0;
    rst_n = 1'b0;
    mem_we = 1'b0;
    mem_addr = 20'd0;
    mem_wdata = 8'sd0;
    ctx_we = 1'b0;
    ctx_idx = 7'd0;
    ctx_n_in = 7'd8;
    ctx_pack = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    start_fwd = 1'b0;
    start_train = 1'b0;
    start_ce = 1'b0;
    start_corpus = 1'b0;
    after_mode = 1'b0;
    do_snap = 1'b0;
    do_restore = 1'b0;
    do_fold = 1'b0;
    tgt_in = 10'd0;
    lr_in = 4'd0;
    corpus_n = 8'd0;
    corpus_ep = 8'd0;

    cyc = 0;
    tok_sets = 0;
    pos_sets = 0;
    rg_switches = 0;
    emb_cycles = 0;
    entered_emb = 1'b0;
    leave_emb = 1'b0;
    timed_out = 1'b0;
    st_prev = 6'd0;
    waddr_prev = 20'd0;
    sub_prev = 4'd0;
    rg_prev = 0;

    $display("E2R-EMB-RG-SWITCH-CXSIM-00 START");
    $display("VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE");
    $display("LAW ST_EMB_sub0=TOK ST_EMB_sub2=POS OFF_TOK=%0d OFF_POS=%0d OFF_L0=%0d D=%0d",
             OFF_TOK, OFF_POS, OFF_L0, D);
    $display("LAW ctx_n=8 UNIT=one_start_fwd_embedding TIMEOUT_CLK=%0d", TIMEOUT_CLK);
    $display("LAW SIM_FULL=1 stall=0 no_DMA_farm");
    $display("PROGRAM=NO");

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);

    @(posedge clk);
    ctx_we <= 1'b1;
    ctx_idx <= 7'd0;
    ctx_n_in <= 7'd8;
    @(posedge clk);
    ctx_we <= 1'b0;
    @(posedge clk);
    #1;
    ntok_h = int'(u_core.ntok);
    $display("CTX_LOAD ntok=%0d ctx_n_in=8", ntok_h);

    @(posedge clk);
    start_fwd <= 1'b1;
    @(posedge clk);
    start_fwd <= 1'b0;

    while (!leave_emb && !timed_out) begin
      @(posedge clk);
      #1;
      st_now = u_core.st;
      waddr_now = u_core.waddr;
      sub_now = u_core.sub;
      rg_now = rg_id(waddr_now);
      cyc = cyc + 1;

      if (st_now == u_core.ST_EMB) begin
        if (!entered_emb) begin
          entered_emb = 1'b1;
          $display("ENTER_EMB cyc=%0d st=%0d waddr=%0d sub=%0d rg=%0d w_stall=%0b",
                   cyc, st_now, waddr_now, sub_now, rg_now, w_stall);
        end
        emb_cycles = emb_cycles + 1;

        if ((sub_now == 4'd1) && (sub_prev == 4'd0)) begin
          tok_sets = tok_sets + 1;
          if ((tok_sets <= 4) || (tok_sets == EXPECT_SETS))
            $display("TOK_SET n=%0d cyc=%0d waddr=%0d sub=%0d tok_i=%0d dim=%0d",
                     tok_sets, cyc, waddr_now, sub_now, u_core.tok_i, u_core.dim);
        end
        if ((sub_now == 4'd3) && (sub_prev == 4'd2)) begin
          pos_sets = pos_sets + 1;
          if ((pos_sets <= 4) || (pos_sets == EXPECT_SETS))
            $display("POS_SET n=%0d cyc=%0d waddr=%0d sub=%0d tok_i=%0d dim=%0d",
                     pos_sets, cyc, waddr_now, sub_now, u_core.tok_i, u_core.dim);
        end
        if (entered_emb && (st_prev == u_core.ST_EMB) && (rg_now != rg_prev) &&
            (rg_now < 2) && (rg_prev < 2)) begin
          rg_switches = rg_switches + 1;
          if (rg_switches <= 6)
            $display("RG_SW n=%0d cyc=%0d prev_rg=%0d now_rg=%0d waddr=%0d",
                     rg_switches, cyc, rg_prev, rg_now, waddr_now);
        end
      end else if (entered_emb) begin
        leave_emb = 1'b1;
        $display("LEAVE_EMB cyc=%0d st=%0d waddr=%0d sub=%0d emb_cycles=%0d",
                 cyc, st_now, waddr_now, sub_now, emb_cycles);
      end

      if (cyc >= TIMEOUT_CLK)
        timed_out = 1'b1;

      st_prev = st_now;
      waddr_prev = waddr_now;
      sub_prev = sub_now;
      rg_prev = rg_now;
    end

    if (!entered_emb || (entered_emb && !leave_emb))
      verdict = "NO_EMB";
    else if ((tok_sets >= (EXPECT_SETS - 16)) && (tok_sets <= (EXPECT_SETS + 16)) &&
             (pos_sets >= (EXPECT_SETS - 16)) && (pos_sets <= (EXPECT_SETS + 16)))
      verdict = "OSC_2ND";
    else if (rg_switches <= 2)
      verdict = "HOLD_RG";
    else
      verdict = "OSC_OTHER";

    classified = 1'b1;

    $display("TOK_SETS=%0d POS_SETS=%0d RG_SWITCHES=%0d EMB_CYCLES=%0d LEAVE_EMB=%0b TIMEOUT=%0b ENTERED=%0b",
             tok_sets, pos_sets, rg_switches, emb_cycles, leave_emb, timed_out, entered_emb);
    $display("EXPECT_SETS=%0d ntok=%0d D=%0d w_stall_end=%0b busy=%0b",
             EXPECT_SETS, ntok_h, D, w_stall, busy);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("EXISTENCE=not_claimed");
    $display("PROGRAM=NO");
    $display("XSIM=%s", verdict);
    $display("VERDICT_CLASS=%s", verdict);
    if (classified)
      $display("E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=%s c_fix=NONE", verdict);
    else
      $display("E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_FAIL verdict=%s c_fix=NONE", verdict);
    $finish;
  end
endmodule
