// LM06-LN-MU-TOKENBOUNDARY-01. PROGRAM=NO. Core-only.
`timescale 1ns / 1ps
`include "../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-LN-MU-TOKENBOUNDARY-01/ln_oracle.svh"

module tb_a7lm06_ln_mu_tokenboundary;
  import a7lm06_pkg::*;
  localparam logic [63:0] UNIT_PACK = 64'h0706050403010002;

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
  logic signed [15:0] oracle_emb [0:1023];
  logic signed [15:0] oracle_n1 [0:1023];
  integer i, fails, wd, t;
  integer nsamp [0:7];
  integer dup [0:7];
  logic [127:0] seen [0:7];
  integer sum_cap [0:7];
  integer fdn_cap [0:7];
  integer fdq_cap [0:7];
  integer mu_cap [0:7];
  integer acc0_ok [0:7];
  integer x_cons, rtl_logit0, emb_mis, n1_mis, emb_first, n1_first;
  logic unit_mode, saw_smx, n1_arm, dumped_n1, dumped_emb, emb_arm;
  integer n1_wait, emb_wait;
  logic signed [15:0] rtl_v, exp_v;

  always @(posedge clk) wd = rst_n ? wd + 1 : 0;

  function automatic int aa(input int tt, input int tk, input int d);
    return tt * 16384 + tk * 128 + d;
  endfunction

  always @(posedge clk) begin
    if (rst_n && unit_mode && busy && int'(u_core.st) == 3 &&
        int'(u_core.ly) == 0 && int'(u_core.ten) == 0) begin
      t = int'(u_core.tok_i);
      if (t < 8) begin
        if (int'(u_core.sub) == 2) begin
          if (nsamp[t] == 0)
            acc0_ok[t] = (u_core.acc === 64'sd0);
          if (seen[t][u_core.dim[6:0]])
            dup[t] = dup[t] + 1;
          seen[t][u_core.dim[6:0]] = 1'b1;
          nsamp[t] = nsamp[t] + 1;
          $display("LN_S_SAMP tok=%0d dim=%0d aaddr=%0d ard=%0d acc_pre=%0d",
                   t, int'(u_core.dim), int'(u_core.aaddr),
                   $isunknown(u_core.ard) ? 32'shdead : int'(u_core.ard),
                   int'(u_core.acc));
        end
        if (int'(u_core.sub) == 3) begin
          sum_cap[t] = int'(u_core.acc);
          fdn_cap[t] = int'(u_core.fd_n);
          $display("LN_S_SUM tok=%0d acc=%0d fd_n=%0d oracle_sum=%0d",
                   t, sum_cap[t], fdn_cap[t], ORACLE_SUM[t]);
        end
        if (int'(u_core.sub) == 4 && u_core.fd_done) begin
          fdq_cap[t] = int'(u_core.fd_q);
          mu_cap[t] = int'(u_core.fd_q);
          $display("LN_S_DIV tok=%0d fd_q=%0d oracle_mu=%0d",
                   t, fdq_cap[t], ORACLE_MU[t]);
        end
      end
    end
    if (rst_n && unit_mode && busy && int'(u_core.st) == 3 &&
        int'(u_core.sub) == 2 && $isunknown(u_core.ard))
      x_cons = x_cons + 1;
    if (rst_n && unit_mode && int'(u_core.st) == 14 && int'(u_core.vix) == 0 && !saw_smx) begin
      saw_smx = 1;
      rtl_logit0 = int'(u_core.logit_q);
    end
  end

  task automatic dump_plane(input int tt, input string tag, inout integer nmis, inout integer first);
    integer tk, d, addr;
    begin
      nmis = 0; first = -1;
      for (tk = 0; tk < 8; tk = tk + 1)
        for (d = 0; d < D; d = d + 1) begin
          addr = aa(tt, tk, d);
          rtl_v = u_core.u_a.mem[addr];
          exp_v = (tt == 0) ? oracle_emb[tk * D + d] : oracle_n1[tk * D + d];
          if ($isunknown(rtl_v) || rtl_v !== exp_v) begin
            if (first < 0) begin
              first = tk * D + d;
              $display("FIRST_MISMATCH %s tk=%0d d=%0d rtl=%0d exp=%0d",
                       tag, tk, d, int'(rtl_v), int'(exp_v));
            end
            nmis = nmis + 1;
          end
        end
      $display("PLANE %s mismatches=%0d first=%0d", tag, nmis, first);
    end
  endtask

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
    fails = 0; wd = 0; unit_mode = 0; saw_smx = 0; x_cons = 0;
    dumped_emb = 0; dumped_n1 = 0; rtl_logit0 = 0;
    emb_mis = 0; n1_mis = 0; emb_first = -1; n1_first = -1;
    mem_we = 0; mem_addr = 0; mem_wdata = 0;
    ctx_we = 0; ctx_idx = 0; ctx_n_in = 0; ctx_pack = 0;
    start_fwd = 0; start_train = 0; start_ce = 0; start_corpus = 0;
    after_mode = 0; do_snap = 0; do_restore = 0; do_fold = 0;
    tgt_in = 0; lr_in = 0; corpus_n = 0; corpus_ep = 0;
    for (i = 0; i < 8; i = i + 1) begin
      nsamp[i] = 0; dup[i] = 0; seen[i] = 0; sum_cap[i] = 0;
      fdn_cap[i] = 0; fdq_cap[i] = 0; mu_cap[i] = 32'h7fffffff; acc0_ok[i] = 0;
    end
    $readmemh("a7lm06_wmem.hex", wmem);
    $readmemh("../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-LN-MU-TOKENBOUNDARY-01/oracle_emb.hex", oracle_emb);
    $readmemh("../../results/A7-NATIVE-GRAPH/GROK-ORCH-00/LM06-LN-MU-TOKENBOUNDARY-01/oracle_n1_l0.hex", oracle_n1);
    repeat (8) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk); mem_we <= 1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 0; mem_addr <= 0; repeat (4) @(posedge clk);
    $display("WMEM_INIT rb0=%0d", mem_rdata);

    load_ctx(7'd1, 64'd1); pulse_fwd; wait_done("CTRL");
    $display("CONTROL pred=%0d", pred);
    if (pred !== 10'd744) begin $display("FAIL CONTROL"); fails++; end
    else $display("CONTROL_PASS pred=744");

    rst_n = 0; repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
    unit_mode = 1;
    load_ctx(7'd8, UNIT_PACK); pulse_fwd; wait_done("UNIT");

    for (i = 0; i < 8; i = i + 1) begin
      $display("TOK_TRACE t=%0d nsamp=%0d dup=%0d acc0=%0d sum=%0d or_sum=%0d mu=%0d or_mu=%0d",
               i, nsamp[i], dup[i], acc0_ok[i], sum_cap[i], ORACLE_SUM[i],
               mu_cap[i], ORACLE_MU[i]);
      if (nsamp[i] != 128)
        $display("H1_MISS_SAMPLES tok=%0d nsamp=%0d want=128", i, nsamp[i]);
      if (nsamp[i] == 128 && sum_cap[i] !== ORACLE_SUM[i])
        $display("H1_BAD_SUM tok=%0d", i);
      if (nsamp[i] == 128 && sum_cap[i] === ORACLE_SUM[i] && mu_cap[i] !== ORACLE_MU[i])
        $display("H2_FLOORDIV tok=%0d sum_ok mu rtl=%0d ref=%0d", i, mu_cap[i], ORACLE_MU[i]);
    end
    if (nsamp[1] == 0) $display("H1_PROOF tok1 never entered ST_LN_S");

    $display("UNIT pred=%0d oracle=%0d logit0=%0d ref=%0d",
             pred, ORACLE_UNIT_PRED, rtl_logit0, ORACLE_UNIT_LOGIT0);
    if (pred !== ORACLE_UNIT_PRED[9:0]) begin $display("FAIL UNIT pred"); fails++; end
    if (rtl_logit0 !== ORACLE_UNIT_LOGIT0) begin $display("FAIL logit0"); fails++; end
    if (emb_mis != 0) begin $display("FAIL EMB"); fails++; end
    if (n1_mis != 0) begin $display("FAIL N1"); fails++; end
    if (x_cons != 0) begin $display("FAIL consumed X"); fails++; end
    for (i = 0; i < 8; i = i + 1)
      if (nsamp[i] != 128 || sum_cap[i] !== ORACLE_SUM[i] || mu_cap[i] !== ORACLE_MU[i])
        fails++;

    if (fails == 0)
      $display("LM06_LN_MU_TOKENBOUNDARY_PASS fails=0");
    else
      $display("LM06_LN_MU_TOKENBOUNDARY_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
