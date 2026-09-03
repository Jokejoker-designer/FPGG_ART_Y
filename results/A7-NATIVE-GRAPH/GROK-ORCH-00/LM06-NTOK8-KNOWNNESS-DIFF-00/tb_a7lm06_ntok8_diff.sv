// LM06-NTOK8-KNOWNNESS-DIFF-00. PROGRAM=NO. Core-only. No graph/MIG.
// Do not edit tiny_gpt803k_core. No arbitrary act-ram zero.
`timescale 1ns / 1ps
`include "../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-NTOK8-KNOWNNESS-DIFF-00/ntok8_oracle.svh"

module tb_a7lm06_ntok8_diff;
  import a7lm06_pkg::*;
  localparam int UNIT_N = 8;
  localparam logic [63:0] UNIT_PACK = 64'h0706050403010002;

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

  logic [7:0] wmem [0:802815];
  logic signed [15:0] oracle_emb [0:1023];
  logic signed [15:0] oracle_n1 [0:1023];
  integer i, fails, wd;
  integer x_wrd, x_ard, x_ard_cons, x_acc, x_logit, x_pred;
  integer first_x_cyc, first_x_addr, first_x_st, first_x_sub;
  integer first_xc_cyc, first_xc_addr, first_xc_st, first_xc_sub, first_xc_tok, first_xc_dim;
  logic got_first_x, got_first_xc, unit_mode, dumped_emb, dumped_n1;
  integer st_i, sub_i, tok_i, dim_i, ly_i, ten_o_i;
  integer emb_mis, n1_mis, emb_first, n1_first;
  integer rtl_logit0;
  logic saw_smx;
  logic signed [15:0] rtl_v, exp_v;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;

  function automatic int aa(input int t, input int tk, input int d);
    return t * 16384 + tk * 128 + d;
  endfunction

  function automatic logic consume();
    int stl, subl;
    stl = int'(u_core.st);
    subl = int'(u_core.sub);
    return busy && (
      (stl == 2 && subl == 2) ||
      (stl == 3 && subl == 2) ||
      (stl == 4 && subl == 2) ||
      (stl == 6 && subl == 2) ||
      (stl == 7 && subl == 2) ||
      (stl == 8 && subl == 2) ||
      (stl == 12 && subl == 2) ||
      (stl == 13 && subl >= 2)
    );
  endfunction

  always @(posedge clk) begin
    if (rst_n && unit_mode && busy) begin
      if ($isunknown(u_core.wrd)) x_wrd = x_wrd + 1;
      if ($isunknown(u_core.ard)) begin
        x_ard = x_ard + 1;
        if (!got_first_x) begin
          got_first_x = 1;
          first_x_cyc = wd;
          first_x_addr = int'(u_core.aaddr);
          first_x_st = int'(u_core.st);
          first_x_sub = int'(u_core.sub);
          $display("FIRST_X_ANY cyc=%0d st=%0d sub=%0d aaddr=%0d tok=%0d dim=%0d",
                   wd, first_x_st, first_x_sub, first_x_addr, int'(u_core.tok_i), int'(u_core.dim));
        end
      end
      if ($isunknown(u_core.acc)) x_acc = x_acc + 1;
      if (consume() && $isunknown(u_core.ard)) begin
        x_ard_cons = x_ard_cons + 1;
        if (!got_first_xc) begin
          got_first_xc = 1;
          first_xc_cyc = wd;
          first_xc_addr = int'(u_core.aaddr);
          first_xc_st = int'(u_core.st);
          first_xc_sub = int'(u_core.sub);
          first_xc_tok = int'(u_core.tok_i);
          first_xc_dim = int'(u_core.dim);
          $display("FIRST_X_CONSUMED cyc=%0d st=%0d sub=%0d aaddr=%0d tok=%0d dim=%0d ly=%0d ten_o=%0d",
                   wd, first_xc_st, first_xc_sub, first_xc_addr, first_xc_tok, first_xc_dim,
                   int'(u_core.ly), int'(u_core.ten_o));
        end
      end
      if ((int'(u_core.st) == 14 || int'(u_core.st) == 15) && $isunknown(u_core.logit_q))
        x_logit = x_logit + 1;
      if (int'(u_core.st) == 14 && int'(u_core.vix) == 0 && !saw_smx) begin
        saw_smx = 1;
        rtl_logit0 = int'(u_core.logit_q);
        $display("RTL_SMX logit0=%0d unknown=%0d", rtl_logit0, $isunknown(u_core.logit_q));
      end
    end
    if (rst_n && unit_mode && done && $isunknown(u_core.pred))
      x_pred = x_pred + 1;
  end

  task automatic wait_done(input string tag);
    integer g;
    begin
      g = 0;
      while (!done && g < 200000000) begin @(posedge clk); g++; end
      if (!done) begin
        $display("FAIL %s timeout phase=%0d", tag, phase);
        fails++;
      end
      @(posedge clk);
    end
  endtask

  task automatic load_ctx(input logic [6:0] n, input logic [63:0] pack);
    begin
      @(posedge clk);
      ctx_we <= 1; ctx_idx <= 0; ctx_n_in <= n; ctx_pack <= pack;
      @(posedge clk);
      ctx_we <= 0;
      @(posedge clk);
    end
  endtask

  task automatic pulse_fwd;
    begin
      @(posedge clk); start_fwd <= 1;
      @(posedge clk); start_fwd <= 0;
    end
  endtask

  task automatic dump_plane(input int t, input string tag, inout integer nmis, inout integer first);
    integer tk, d, addr;
    begin
      nmis = 0; first = -1;
      for (tk = 0; tk < UNIT_N; tk = tk + 1)
        for (d = 0; d < D; d = d + 1) begin
          addr = aa(t, tk, d);
          rtl_v = u_core.u_a.mem[addr];
          exp_v = (t == 0) ? oracle_emb[tk * D + d] : oracle_n1[tk * D + d];
          if ($isunknown(rtl_v) || rtl_v !== exp_v) begin
            if (first < 0) begin
              first = tk * D + d;
              $display("FIRST_MISMATCH %s tk=%0d d=%0d addr=%0d rtl=%0d exp=%0d x=%0d",
                       tag, tk, d, addr, $isunknown(rtl_v) ? 32'shdead : int'(rtl_v),
                       int'(exp_v), $isunknown(rtl_v));
            end
            nmis = nmis + 1;
          end
        end
      $display("PLANE %s mismatches=%0d first=%0d", tag, nmis, first);
    end
  endtask

  logic emb_arm, n1_arm;
  integer emb_wait, n1_wait;

  always @(posedge clk) begin
    if (!rst_n || !unit_mode) begin
      emb_arm <= 0; n1_arm <= 0; emb_wait <= 0; n1_wait <= 0;
    end else begin
      if (!emb_arm && u_core.st == 6'd3) begin
        emb_arm <= 1; emb_wait <= 4;
      end
      if (emb_wait > 0) begin
        emb_wait <= emb_wait - 1;
        if (emb_wait == 1 && !dumped_emb) begin
          dump_plane(0, "EMB", emb_mis, emb_first);
          dumped_emb <= 1;
        end
      end
      if (!n1_arm && u_core.st == 6'd7 && u_core.ten_o == 3'd2) begin
        n1_arm <= 1; n1_wait <= 4;
      end
      if (n1_wait > 0) begin
        n1_wait <= n1_wait - 1;
        if (n1_wait == 1 && !dumped_n1) begin
          dump_plane(1, "N1_L0", n1_mis, n1_first);
          dumped_n1 <= 1;
        end
      end
    end
  end

  initial begin
    wait (wd > 800000000);
    $display("FAIL watchdog");
    $finish;
  end

  initial begin
    fails = 0; wd = 0;
    x_wrd = 0; x_ard = 0; x_ard_cons = 0; x_acc = 0; x_logit = 0; x_pred = 0;
    got_first_x = 0; got_first_xc = 0; unit_mode = 0; dumped_emb = 0; dumped_n1 = 0;
    saw_smx = 0; rtl_logit0 = 0;
    mem_we = 0; mem_addr = 0; mem_wdata = 0;
    ctx_we = 0; ctx_idx = 0; ctx_n_in = 0; ctx_pack = 0;
    start_fwd = 0; start_train = 0; start_ce = 0; start_corpus = 0;
    after_mode = 0; do_snap = 0; do_restore = 0; do_fold = 0;
    tgt_in = 0; lr_in = 0; corpus_n = 0; corpus_ep = 0;

    $readmemh("a7lm06_wmem.hex", wmem);
    $readmemh("../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-NTOK8-KNOWNNESS-DIFF-00/oracle_emb.hex", oracle_emb);
    $readmemh("../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-NTOK8-KNOWNNESS-DIFF-00/oracle_n1_l0.hex", oracle_n1);

    repeat (8) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk);
    mem_we <= 0; mem_addr <= 0;
    repeat (4) @(posedge clk);
    if (mem_rdata !== wmem[0]) begin
      $display("FAIL readback0 got=%0d exp=%0d", mem_rdata, wmem[0]);
      fails++;
    end else
      $display("WMEM_INIT ok n=%0d rb0=%0d", NPARAM, mem_rdata);

    // CONTROL ntok=1 token=1 golden 744
    load_ctx(7'd1, 64'd1);
    pulse_fwd;
    wait_done("CTRL");
    $display("CONTROL pred=%0d oracle=%0d", pred, ORACLE_CTRL_PRED);
    if (pred !== ORACLE_CTRL_PRED[9:0]) begin
      $display("FAIL CONTROL pred — TB/image init");
      fails++;
    end else
      $display("CONTROL_PASS pred=744");

    rst_n = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);

    unit_mode = 1;
    emb_mis = 0; n1_mis = 0; emb_first = -1; n1_first = -1;
    load_ctx(7'd8, UNIT_PACK);
    $display("UNIT ctx ntok=8 pack=%h", UNIT_PACK);
    pulse_fwd;
    wait_done("UNIT");
    $display("UNIT pred=%0d oracle=%0d logit0_rtl=%0d logit0_ref=%0d",
             pred, ORACLE_UNIT_PRED, rtl_logit0, ORACLE_UNIT_LOGIT0);
    if (pred !== ORACLE_UNIT_PRED[9:0]) begin
      $display("FAIL UNIT OUT rtl=%0d ref=%0d", pred, ORACLE_UNIT_PRED);
      fails++;
    end
    if (saw_smx && rtl_logit0 !== ORACLE_UNIT_LOGIT0) begin
      $display("FAIL UNIT logit0 rtl=%0d ref=%0d", rtl_logit0, ORACLE_UNIT_LOGIT0);
      fails++;
    end
    if (emb_mis != 0) begin
      $display("FAIL EMB mismatches=%0d first=%0d", emb_mis, emb_first);
      fails++;
    end
    if (n1_mis != 0) begin
      $display("FAIL N1_L0 mismatches=%0d first=%0d", n1_mis, n1_first);
      fails++;
    end

    $display("X_COUNT wrd=%0d ard_any=%0d ard_consumed=%0d acc=%0d logit=%0d pred=%0d",
             x_wrd, x_ard, x_ard_cons, x_acc, x_logit, x_pred);
    if (got_first_x)
      $display("FIRST_X_ANY_SUMMARY cyc=%0d st=%0d sub=%0d aaddr=%0d",
               first_x_cyc, first_x_st, first_x_sub, first_x_addr);
    if (got_first_xc)
      $display("FIRST_X_CONSUMED_SUMMARY cyc=%0d st=%0d sub=%0d aaddr=%0d tok=%0d dim=%0d",
               first_xc_cyc, first_xc_st, first_xc_sub, first_xc_addr, first_xc_tok, first_xc_dim);
    else
      $display("FIRST_X_CONSUMED none");

    if (x_ard_cons != 0 || x_wrd != 0 || x_acc != 0 || x_logit != 0 || x_pred != 0) begin
      $display("FAIL x_unknown consumed/path nonzero");
      fails++;
    end

    if (fails == 0)
      $display("LM06_NTOK8_KNOWNNESS_DIFF_PASS fails=0");
    else
      $display("LM06_NTOK8_KNOWNNESS_DIFF_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
