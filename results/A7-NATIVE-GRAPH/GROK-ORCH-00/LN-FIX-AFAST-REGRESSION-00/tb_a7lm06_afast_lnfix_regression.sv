// LN-FIX-AFAST-REGRESSION-00. PROGRAM=NO. Core-only A/B.
// +ARM=OLD | +ARM=NEW  (default NEW)
`timescale 1ns / 1ps
`include "../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LN-FIX-AFAST-REGRESSION-00/afast_oracle.svh"

module tb_a7lm06_afast_lnfix_regression;
  import a7lm06_pkg::*;
  localparam int NPARAM = 802816;

  logic clk = 0, rst_n = 0;
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
  integer i, fails, wd, rtl_logit0;
  logic saw_smx;
  string arm;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;

  always @(posedge clk) begin
    if (rst_n && busy && int'(u_core.st) == 14 && int'(u_core.vix) == 0 && !saw_smx) begin
      saw_smx = 1;
      rtl_logit0 = int'(u_core.logit_q);
    end
  end

  task automatic wait_done(input string tag);
    integer g;
    begin
      g = 0;
      while (!done && g < 200000000) begin @(posedge clk); g++; end
      if (!done) begin $display("FAIL %s timeout", tag); fails++; end
      @(posedge clk);
    end
  endtask

  task automatic load_ctx(input logic [6:0] n, input logic [63:0] pack);
    begin
      @(posedge clk); ctx_we <= 1; ctx_idx <= 0; ctx_n_in <= n; ctx_pack <= pack;
      @(posedge clk); ctx_we <= 0; @(posedge clk);
    end
  endtask

  task automatic pulse_fwd;
    begin @(posedge clk); start_fwd <= 1; @(posedge clk); start_fwd <= 0; end
  endtask

  initial begin
    wait (wd > 800000000);
    $display("FAIL watchdog"); $finish;
  end

  initial begin
    fails = 0; wd = 0; saw_smx = 0; rtl_logit0 = 0;
    mem_we = 0; mem_addr = 0; mem_wdata = 0;
    ctx_we = 0; ctx_idx = 0; ctx_n_in = 0; ctx_pack = 0;
    start_fwd = 0; start_train = 0; start_ce = 0; start_corpus = 0;
    after_mode = 0; do_snap = 0; do_restore = 0; do_fold = 0;
    tgt_in = 0; lr_in = 0; corpus_n = 0; corpus_ep = 0;
`ifdef ARM_OLD
    arm = "OLD";
`else
    arm = "NEW";
`endif
    $display("ARM=%s PACK=%h CTX_N=%0d", arm, PACK_AFAST, CTX_N);
    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk); mem_we <= 1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 0; mem_addr <= 0; repeat (4) @(posedge clk);
    $display("WMEM_INIT rb0=%0d", mem_rdata);

    load_ctx(7'd1, 64'd1); pulse_fwd; wait_done("CTRL");
    $display("CONTROL pred=%0d logit0=%0d", pred, rtl_logit0);
    if (pred !== 10'd744) begin $display("FAIL CONTROL pred"); fails++; end
    if (rtl_logit0 !== ORACLE_CTRL_LOGIT0) begin $display("FAIL CONTROL logit0"); fails++; end
    else $display("CONTROL_PASS pred=744");

    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    saw_smx = 0; rtl_logit0 = 0;
    load_ctx(CTX_N, PACK_AFAST); pulse_fwd; wait_done("AFAST");
    $display("AFAST_ARM=%s pred=%0d logit0=%0d python_pred=%0d python_logit0=%0d historical_664=%0d",
             arm, pred, rtl_logit0, ORACLE_UNIT_PRED, ORACLE_UNIT_LOGIT0, HISTORICAL_PRED);

    if (arm == "OLD") begin
      if (pred == 10'(HISTORICAL_PRED))
        $display("HISTORICAL_664_REPRO old_pred=664");
      else
        $display("HISTORICAL_664_NOT_ON_THIS_WMEM old_pred=%0d", pred);
      $display("OLD_CORE pred=%0d logit0=%0d", pred, rtl_logit0);
    end else begin
      if (pred !== ORACLE_UNIT_PRED[9:0]) begin
        $display("FAIL NEW pred=%0d python=%0d", pred, ORACLE_UNIT_PRED);
        fails++;
      end
      if (rtl_logit0 !== ORACLE_UNIT_LOGIT0) begin
        $display("FAIL NEW logit0=%0d python=%0d", rtl_logit0, ORACLE_UNIT_LOGIT0);
        fails++;
      end
      if (pred != 10'(HISTORICAL_PRED))
        $display("SEMANTIC_CHANGE_EXACT pred=%0d python=%0d historical_664_old_sha=29D230FC",
                 pred, ORACLE_UNIT_PRED);
      else
        $display("EXACT_REGRESSION pred=664 equals python");
    end

    if (fails == 0)
      $display("LN_FIX_AFAST_REGRESSION_PASS arm=%s fails=0 pred=%0d", arm, pred);
    else
      $display("LN_FIX_AFAST_REGRESSION_FAIL arm=%s fails=%0d pred=%0d", arm, fails, pred);
    $finish;
  end
endmodule
