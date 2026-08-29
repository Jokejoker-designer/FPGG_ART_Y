`timescale 1ns / 1ps
import a7lm06_pkg::*;
// E2R-FWD-RG-SWITCH-CXSIM-00 — start_fwd to done TOK/POS/other waddr set count.
// Copy of tb_e2r_emb_rg_switch_cxsim_00.sv. One change: do not stop at leave ST_EMB.
// Watch until done==1 or TIMEOUT_CLK (40000000 >= 5000000). Keep SIM_FULL=1.
// Instantiates tiny_gpt803k_core #(.SIM_FULL(1)) only. No SoC. No MIG.
// Do not edit rtl/**. PROGRAM=NO. C_FIX=NONE.
module tb_e2r_fwd_rg_switch_cxsim_00;
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

  // Preregistered minimum is 5_000_000. 40e6 covers ~18e6 ST_MV cycles + LN/attn/head.
  localparam int TIMEOUT_CLK = 40000000;
  localparam int EXPECT_SETS = 8 * D;
  localparam int HEARTBEAT = 1000000;

  function automatic bit is_tok_rg(input logic [19:0] a);
    return (a < 20'(OFF_POS));
  endfunction

  function automatic bit is_pos_rg(input logic [19:0] a);
    return (a >= 20'(OFF_POS)) && (a < 20'(OFF_L0));
  endfunction

  function automatic bit is_other_rg(input logic [19:0] a);
    return !is_tok_rg(a) && !is_pos_rg(a);
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
    int other_sets;
    int rg_switches;
    int emb_cycles;
    int after_emb_tok;
    int after_emb_pos;
    int after_emb_other;
    int after_emb_sets;
    int total_sets;
    bit entered_emb;
    bit leave_emb;
    bit timed_out;
    bit saw_done;
    bit classified;
    bit issued;
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
    other_sets = 0;
    rg_switches = 0;
    emb_cycles = 0;
    after_emb_tok = 0;
    after_emb_pos = 0;
    after_emb_other = 0;
    after_emb_sets = 0;
    entered_emb = 1'b0;
    leave_emb = 1'b0;
    timed_out = 1'b0;
    saw_done = 1'b0;
    st_prev = 6'd0;
    waddr_prev = 20'd0;
    sub_prev = 4'd0;
    rg_prev = 0;

    $display("E2R-FWD-RG-SWITCH-CXSIM-00 START");
    $display("VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE");
    $display("LAW OFF_TOK=%0d OFF_POS=%0d OFF_L0=%0d OFF_HEAD=%0d D=%0d",
             OFF_TOK, OFF_POS, OFF_L0, OFF_HEAD, D);
    $display("LAW ctx_n=8 UNIT=one_start_fwd_until_done TIMEOUT_CLK=%0d", TIMEOUT_CLK);
    $display("LAW SIM_FULL=1 stall=0 no_DMA_farm STOP=done_or_timeout NOT_leave_ST_EMB");
    $display("LAW SET=ST_EMB_sub0to1_TOK|ST_EMB_sub2to3_POS|after_emb_waddr_change");
    $display("LAW OTHER=waddr_not_in_TOK_or_POS");
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

    while (!saw_done && !timed_out) begin
      @(posedge clk);
      #1;
      st_now = u_core.st;
      waddr_now = u_core.waddr;
      sub_now = u_core.sub;
      rg_now = rg_id(waddr_now);
      cyc = cyc + 1;
      issued = 1'b0;

      if (st_now == u_core.ST_EMB) begin
        if (!entered_emb) begin
          entered_emb = 1'b1;
          $display("ENTER_EMB cyc=%0d st=%0d waddr=%0d sub=%0d rg=%0d w_stall=%0b",
                   cyc, st_now, waddr_now, sub_now, rg_now, w_stall);
        end
        emb_cycles = emb_cycles + 1;

        if ((sub_now == 4'd1) && (sub_prev == 4'd0)) begin
          tok_sets = tok_sets + 1;
          issued = 1'b1;
          if ((tok_sets <= 4) || (tok_sets == EXPECT_SETS))
            $display("TOK_SET n=%0d cyc=%0d waddr=%0d sub=%0d tok_i=%0d dim=%0d after=%0b",
                     tok_sets, cyc, waddr_now, sub_now, u_core.tok_i, u_core.dim, leave_emb);
        end
        if ((sub_now == 4'd3) && (sub_prev == 4'd2)) begin
          pos_sets = pos_sets + 1;
          issued = 1'b1;
          if ((pos_sets <= 4) || (pos_sets == EXPECT_SETS))
            $display("POS_SET n=%0d cyc=%0d waddr=%0d sub=%0d tok_i=%0d dim=%0d after=%0b",
                     pos_sets, cyc, waddr_now, sub_now, u_core.tok_i, u_core.dim, leave_emb);
        end
        if (entered_emb && (st_prev == u_core.ST_EMB) && (rg_now != rg_prev) &&
            (rg_now < 2) && (rg_prev < 2)) begin
          rg_switches = rg_switches + 1;
          if (rg_switches <= 6)
            $display("RG_SW n=%0d cyc=%0d prev_rg=%0d now_rg=%0d waddr=%0d",
                     rg_switches, cyc, rg_prev, rg_now, waddr_now);
        end
      end else if (entered_emb) begin
        if (!leave_emb) begin
          leave_emb = 1'b1;
          $display("LEAVE_EMB cyc=%0d st=%0d waddr=%0d sub=%0d emb_cycles=%0d tok=%0d pos=%0d other=%0d",
                   cyc, st_now, waddr_now, sub_now, emb_cycles, tok_sets, pos_sets, other_sets);
        end
        if (waddr_now !== waddr_prev) begin
          issued = 1'b1;
          if (is_tok_rg(waddr_now)) begin
            tok_sets = tok_sets + 1;
            after_emb_tok = after_emb_tok + 1;
          end else if (is_pos_rg(waddr_now)) begin
            pos_sets = pos_sets + 1;
            after_emb_pos = after_emb_pos + 1;
          end else begin
            other_sets = other_sets + 1;
            after_emb_other = after_emb_other + 1;
          end
          after_emb_sets = after_emb_sets + 1;
          if (rg_now != rg_prev)
            rg_switches = rg_switches + 1;
          if ((after_emb_sets <= 4) || ((after_emb_sets % 1000000) == 0))
            $display("AFTER_SET n=%0d cyc=%0d st=%0d waddr=%0d rg=%0d tok=%0d pos=%0d other=%0d ly=%0d",
                     after_emb_sets, cyc, st_now, waddr_now, rg_now,
                     tok_sets, pos_sets, other_sets, u_core.ly);
        end
      end

      if (done) begin
        saw_done = 1'b1;
        $display("CORE_DONE cyc=%0d st=%0d pred=%0d waddr=%0d tok=%0d pos=%0d other=%0d after=%0d",
                 cyc, st_now, pred, waddr_now, tok_sets, pos_sets, other_sets, after_emb_sets);
      end

      if ((cyc % HEARTBEAT) == 0)
        $display("HEARTBEAT cyc=%0d st=%0d waddr=%0d tok=%0d pos=%0d other=%0d after=%0d done=%0b leave=%0b",
                 cyc, st_now, waddr_now, tok_sets, pos_sets, other_sets, after_emb_sets, done, leave_emb);

      if (cyc >= TIMEOUT_CLK)
        timed_out = 1'b1;

      st_prev = st_now;
      waddr_prev = waddr_now;
      sub_prev = sub_now;
      rg_prev = rg_now;
    end

    total_sets = tok_sets + pos_sets + other_sets;

    if (!entered_emb)
      verdict = "NO_EMB";
    else if (!saw_done)
      verdict = "NO_DONE";
    else if (after_emb_sets <= 64)
      verdict = "EMB_DOM";
    else if ((other_sets > 64) || (total_sets > (2048 + 64)))
      verdict = "FWD_HEAVY";
    else
      verdict = "EMB_DOM";

    classified = 1'b1;

    $display("TOK_SETS=%0d POS_SETS=%0d OTHER_SETS=%0d TOTAL_SETS=%0d RG_SWITCHES=%0d",
             tok_sets, pos_sets, other_sets, total_sets, rg_switches);
    $display("AFTER_EMB_TOK=%0d AFTER_EMB_POS=%0d AFTER_EMB_OTHER=%0d AFTER_EMB_SETS=%0d",
             after_emb_tok, after_emb_pos, after_emb_other, after_emb_sets);
    $display("EMB_CYCLES=%0d CYCLES=%0d LEAVE_EMB=%0b DONE=%0b TIMEOUT=%0b ENTERED=%0b",
             emb_cycles, cyc, leave_emb, saw_done, timed_out, entered_emb);
    $display("EXPECT_EMB_SETS=%0d ntok=%0d D=%0d pred=%0d w_stall_end=%0b busy=%0b",
             EXPECT_SETS, ntok_h, D, pred, w_stall, busy);
    $display("C_FIX=NONE");
    $display("BOARD_PASS=not_claimed");
    $display("EXISTENCE=not_claimed");
    $display("PROGRAM=NO");
    $display("XSIM=%s", verdict);
    $display("VERDICT_CLASS=%s", verdict);
    if (classified)
      $display("E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=%s c_fix=NONE", verdict);
    else
      $display("E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_FAIL verdict=%s c_fix=NONE", verdict);
    $finish;
  end
endmodule
